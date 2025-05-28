library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity fifo_sync_tb is
end fifo_sync_tb;

architecture fifo_sync_tb of fifo_sync_tb is
    signal clk_tb : std_logic := '1';
    signal rst_tb : std_logic := '0';
    signal wr_en_tb : std_logic := '0';
    signal wr_data_tb : std_logic_vector ( 7 downto 0 ) := (others=>'0');
    signal rd_en_tb : std_logic := '0';
    signal rd_data_tb : std_logic_vector ( 7 downto 0 );
    signal sts_full_tb : std_logic;
    signal sts_empty_tb : std_logic;
    signal sts_high_tb : std_logic;
    signal sts_low_tb : std_logic;
    signal sts_error_tb : std_logic;
begin

    clk_tb <= not clk_tb after 5 ns;
    rst_tb <= '0',
        --'1' after 1 ns, '0' after 4 ns,
        '1' after 1000 ns, '0' after 1020 ns,
        '1' after 1640 ns, '0' after 1643 ns;
        --funciona como waveform concurrente

    fifo: entity work.FIFO_SYNC port map(
        clk => clk_tb,
        rst => rst_tb,
        wr_en => wr_en_tb,
        wr_data => wr_data_tb,
        rd_en => rd_en_tb,
        rd_data => rd_data_tb,
        sts_full => sts_full_tb,
        sts_empty => sts_empty_tb,
        sts_high => sts_high_tb,
        sts_low => sts_low_tb,
        sts_error => sts_error_tb
    );

    process
    begin
                -- wait until rst_tb = '1' and rising_edge(clk_tb);-- espera o reset completar
        wait for 200 ns; -- EMPTY -- 0 ns Delta Cycle

        wr_en_tb <= '1';
        rd_en_tb <= '1';
        wr_data_tb <= x"B1";
        wait for 20 ns; -- EMPTY == escrita e leitura ao mesmo tempo -- 200 ns Delta Cycle

        wr_data_tb <= x"B2";
        rd_en_tb <= '0';
        wait for 30 ns; -- LOW -- 220 ns Delta Cycle

                wr_en_tb <= '0';
        rd_en_tb <= '1';
        wait for 40 ns; -- "underflow" -- 250 ns Delta Cycle

        wr_en_tb <= '1';
        rd_en_tb <= '0';
        wr_data_tb <= x"B3";
        wait for 590 ns;-- escreve ate HIGH (60x) -- 290 ns Delta Cycle

        wr_en_tb <= '0';
                rd_en_tb <= '1';
        wait for 10 ns; -- HIGH e le 1 pra sair do high -- 880 ns Delta Cycle

        rd_en_tb <= '0';
        wr_en_tb <= '1';
        wr_data_tb <= x"B4";
        wait for 40 ns; -- escreve ate FULL -- 890 ns Delta Cycle

        wr_en_tb <= '0';
                rd_en_tb <= '1';
        wait for 10 ns; --le para sair do full -- 920 ns Delta Cycle

        rd_en_tb <= '0';
                wr_en_tb <= '1';
        wr_data_tb <= x"B5";
        wait for 10 ns; -- enche de novo -- 930 ns Delta Cycle

        wr_en_tb <= '1';
        rd_en_tb <= '1';
        wr_data_tb <= x"B6";
        wait for 10 ns; -- limite em full -- 940 ns Delta Cycle

        rd_en_tb <= '1';
        wait for 10 ns; -- OVERFLOW -- 950 ns Delta Cycle

        rd_en_tb <= '0';
        wr_en_tb <= '1';
        wr_data_tb <= x"FF";
        wait for 670 ns;-- OVERFLOW e tentativa de leitura-- 980 ns Delta Cycle  --
                --([970,1019] = OVERFLOW) ->( 1020= reset ) -> ([1020,1640] = 62 x"FF" = HIGH)

                rd_en_tb <= '1';
                wr_en_tb <= '0';
                -- ([1640] = reset)
                wait for 300 ns;-- 1640 ns Delta Cycle
                -- ([1940] = Underflow)

    end process;

end fifo_sync_tb;
