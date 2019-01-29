#include <libopencm3/stm32/rcc.h>
#include <libopencm3/cm3/nvic.h>
#include <libopencm3/stm32/gpio.h>
#include <libopencm3/stm32/usart.h>

static void usart_disable_txc_interrupt(uint32_t usart)
{
	USART_CR1(usart) &= ~USART_CR1_TCIE;
}

static void usart_enable_txc_interrupt(uint32_t usart)
{
	USART_CR1(usart) |= USART_CR1_TCIE;
}

static void usart_setup(void)
{
	nvic_enable_irq(NVIC_USART1_IRQ);

	gpio_set_mode(GPIOA, GPIO_MODE_OUTPUT_50_MHZ,
				  GPIO_CNF_OUTPUT_ALTFN_PUSHPULL, GPIO_USART1_TX);

	gpio_set_mode(GPIOA, GPIO_MODE_INPUT,
				  GPIO_CNF_INPUT_FLOAT, GPIO_USART1_RX);

	usart_set_baudrate(USART1, 57600);
	usart_set_databits(USART1, 8);
	usart_set_stopbits(USART1, USART_STOPBITS_1);
	usart_set_parity(USART1, USART_PARITY_NONE);
	usart_set_flow_control(USART1, USART_FLOWCONTROL_NONE);
	usart_set_mode(USART1, USART_MODE_TX_RX);

	usart_enable_rx_interrupt(USART1);

	usart_enable(USART1);
}

static int j =0, c = 0;
static uint16_t rdata = 0 + '0';

void usart1_isr(void)
{
	const uint32_t irq_reg = USART_CR1(USART1);
	const uint32_t irq_status = USART_SR(USART1);
	if ((irq_reg & USART_CR1_TXEIE) != 0 &&
			(irq_status & USART_SR_TXE) != 0) {

		usart_disable_tx_interrupt(USART1);
		usart_enable_txc_interrupt(USART1);
		usart_send(USART1, rdata);

	} else if ((irq_reg & USART_CR1_TCIE) != 0 &&
			   (irq_status & USART_SR_TC) != 0) {

		gpio_toggle(GPIOA, GPIO1);
		usart_disable_txc_interrupt(USART1);
		gpio_toggle(GPIOC, GPIO13);

	} else if ((irq_reg & USART_CR1_RXNEIE) != 0 &&
			   (irq_status & USART_SR_RXNE) != 0) {

		rdata = usart_recv(USART1);
		usart_enable_tx_interrupt(USART1);
	}
}

static void gpio_setup(void)
{
	gpio_set_mode(GPIOA, GPIO_MODE_OUTPUT_2_MHZ,
		      GPIO_CNF_OUTPUT_PUSHPULL, GPIO1);
}

static void clock_setup(void)
{
	rcc_clock_setup_in_hse_8mhz_out_72mhz();
	rcc_periph_clock_enable(RCC_GPIOA);
}

int main(void)
{
	clock_setup();
	gpio_setup();
	usart_setup();

	while(1);

	return 0;
}
