library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
 
entity diy_uart is
    Generic(
        baud_scaler : integer := 2604
    );
    Port(
        
        clk_50Mhz : in STD_LOGIC;
        tx_out : out STD_LOGIC;
--        state : out STD_LOGIC_VECTOR(1 downto 0);
        clk_out : out STD_LOGIC
--        data_out : out STD_LOGIC_VECTOR(7 downto 0)
    );
end diy_uart;
 
architecture Behavioral of diy_uart is
type data_array is array (0 to 3) of STD_LOGIC_VECTOR(7 downto 0);
--signal uart_tx_data : data_array :=(
--  0 => x"41",
--  1 => x"59",
--  2 => x"60",
--  3 => x"0D" 
--);
type uart_tx_state is (idle, start, data, stop);
--type send_state
signal uart_tx_sig : uart_tx_state := idle;
signal send_cnt : integer range 0 to 4;
signal scale_cnt : integer range 0 to baud_scaler - 1;
signal clk_temp : STD_LOGIC := '0';
signal uart_tx_data : STD_LOGIC_VECTOR(7 downto 0);
signal byte_cnt : integer range 0 to 200 := 0;
signal din : STD_LOGIC_VECTOR(11 downto 0) := "000100110010";
signal adc_data1, adc_data2, adc_data3 : std_logic_vector(3 downto 0);
 
begin
    clock_scale_proc : process(clk_50Mhz)
    begin
        if rising_edge(clk_50Mhz) then
            if scale_cnt = baud_scaler - 1 then
                clk_temp <= not (clk_temp);
                scale_cnt <= 0;
            else
                scale_cnt <= scale_cnt + 1;
            end if;
        end if;
    end process clock_scale_proc;
    clk_out <= clk_temp;
    uart_tx_proc : process(clk_temp)
    begin
        if rising_edge(clk_temp) then
            if send_cnt <= 4 then
--               data_out <= uart_tx_data;
                case uart_tx_sig is
                when idle =>
                    if byte_cnt = 0 then
                        tx_out <= '1';
 --                       state <= "00";
                        uart_tx_sig <= start;
                        byte_cnt <= 0;
                    else
                        byte_cnt <= byte_cnt + 1;
                    end if;
                when start =>
 --                   state <= "01";
                    tx_out <= '0';
                    uart_tx_sig <= data;
                when data =>
 --                   state <= "10";                         
                    if byte_cnt = 7 then
                        adc_data1 <= din(11 downto 8);
                        adc_data2 <= din(7 downto 4);
                        adc_data3 <= din(3 downto 0);
                        case (send_cnt) is
                        when 1 => uart_tx_data <= x"41";
                        when 2 => uart_tx_data <= "0011" & adc_data1;
                        when 3 => uart_tx_data <= adc_data2 & adc_data3;
                        when 4 => uart_tx_data <= x"0A";
                        when others => uart_tx_data <= "00000000";
                        end case;
                   
                        tx_out <= uart_tx_data(byte_cnt);
                        byte_cnt <= 0;
                        uart_tx_sig <= stop;
                    else
                        tx_out <= uart_tx_data(byte_cnt);
                        byte_cnt <= byte_cnt + 1;
                    end if;
                   
                when stop =>
--                    state <= "11";
                    tx_out <= '1';
                    uart_tx_sig <= idle;
                    send_cnt <= send_cnt + 1;
                end case;
            else
                send_cnt <= 0;
            end if;
        end if;
    end process uart_tx_proc;
end Behavioral;
