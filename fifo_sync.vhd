library ieee;
        use ieee.std_logic_1164.all;
        use ieee.std_logic_unsigned.all;
        use ieee.std_logic_arith.all;

entity fifo_sync is
    generic (
        MEMORY_SIZE : integer := 64
    );
        port(
                clk             : in std_logic;
                rst             : in std_logic;
                wr_en           : in std_logic;
                wr_data         : in std_logic_vector(7 downto 0);
                rd_en           : in std_logic;
                rd_data         : out std_logic_vector(7 downto 0);
                sts_full        : out std_logic;
                sts_empty       : out std_logic;
                sts_high        : out std_logic;
                sts_low         : out std_logic;
                sts_error       : out std_logic
        );
end fifo_sync;

architecture rtl of fifo_sync is
        type MEMORY is array (0 to MEMORY_SIZE-1) of std_logic_vector(7 downto 0);
        type STATES is (LIMBO, EMPTY, LOWS, HIGHS, FULL ,OVERFLOW);
        signal fifo_data : MEMORY := (others => (others => '0'));
        signal filled :integer range 0 to MEMORY_SIZE+1 := 0;
        signal wp, rp :integer range 0 to MEMORY_SIZE-1 := 0;
        signal state, prev_state : STATES := EMPTY;
        signal sig_full, sig_empty , sig_high, sig_low, sig_error: std_logic;

begin

        sanity_limit_check: assert MEMORY_SIZE >= 8 report "MEMORY_SIZE tem que ser maior que 8" severity FAILURE;

        process(clk, rst)
        begin
                prev_state <= state;
                if rst = '1' then
                        fifo_data <= (others => (others => '0'));
                        prev_state <= EMPTY;
                        sig_error <= '0';
                        wp <= 0;
                        rp <= 0;
                elsif rising_edge(clk) then
				  --prev_state <= state;
                  case state is
                        when EMPTY =>
                          if (wr_en = '1' and rd_en = '1') then
                                rd_data       <= wr_data;
                                sig_error     <= '0';
                                fifo_data(wp) <= wr_data;
								rp <= (rp + 1) mod MEMORY_SIZE;
								wp <= (wp + 1) mod MEMORY_SIZE;

                          elsif (wr_en = '1' and rd_en = '0') then
                                fifo_data(wp) <= wr_data;
                                wp <= (wp + 1) mod MEMORY_SIZE;

                          else
                                assert (wr_en = '1' or rd_en = '0')
                                  report "Tentativa de leitura em FIFO vazia (UNDERFLOW!)" severity WARNING;
                          end if;

                        when FULL =>
                          if (rd_en = '0' and wr_en = '1') then
                                sig_error <= '1';
                          else
                                if (rd_en = '1') then
                                  rd_data <= fifo_data(rp);
                                  rp <= (rp + 1) mod MEMORY_SIZE;
                                end if;

                                if (wr_en = '1') then
                                  fifo_data(wp) <= wr_data;
                                  wp <= (wp + 1) mod MEMORY_SIZE;
                                end if;
                          end if;

                        when OVERFLOW => -- Tratamento de overflow
                                if (rd_en = '1') then
                                        rd_data   <= (others => 'U'); -- Somente simulacao | Na realidade somente 0 ou 1
										-- rd_data   <= (others => '0'); -- Sintetizavel
										-- rd_data   <= (others => '1'); -- Sintetizavel
                                        sig_error <= '1';
                                end if;
								
								-- Normalmente se permetiria leitura.
                                assert (wr_en = '0' and rd_en = '0') report "RESET (OVERFLOW!)" severity WARNING;

                        when others => -- Outros estados: HIGH, LOW, E INTERMEDIÁRIOS
                          if (rd_en = '1') then
                                rd_data <= fifo_data(rp);
                                rp <= (rp + 1) mod MEMORY_SIZE;
                          end if;

                          if (wr_en = '1') then
                                fifo_data(wp) <= wr_data;
                                wp <= (wp + 1) mod MEMORY_SIZE;
                          end if;

                  end case;
                end if;
        end process;

        filled <= 0 when rst = '1' else -- Tava pensando em por os sts_* mas assim é melhor
				  0 when (wp = rp and (prev_state /= FULL or prev_state = EMPTY or prev_state = LOWS)) else
				  MEMORY_SIZE when (wp = rp and prev_state = FULL) else
				  (wp - rp) when (wp > rp) else
				  (MEMORY_SIZE - rp + wp + 1) when (wp < rp and (prev_state = FULL or prev_state /= EMPTY or prev_state /= LOWS)) else
                  0;

        ---------------- empty -------------------
        sig_empty <= '1' when rst = '1' else
                     '1' when (filled = 0 and prev_state /= HIGHS) else
                     '0';
        sts_empty <= sig_empty;
        ---------------- low ---------------------
        sig_low <= '1' when rst = '1' else
                   '1' when (filled <= 4 and filled >= 1) else
                   '0';
        sts_low <= sig_low;
        ---------------- high ---------------------
        sig_high <= '0' when rst = '1' else
                    '1' when (filled >= MEMORY_SIZE-4 and filled <MEMORY_SIZE)else
                    '0';
        sts_high <= sig_high;
        ---------------- full ---------------------
        sig_full <= '0' when rst = '1' else
                    '1' when (filled = MEMORY_SIZE) else
                    '0';
        sts_full <= sig_full;
        ---------------- error --------------------
        sts_error <= sig_error;

        ---------------- default --------------------

        ---------------- STATES -------------------
        state <= OVERFLOW when sig_error = '1'else
                         EMPTY when sig_empty = '1' or rst = '1' else
                         LOWS when sig_low = '1' else
                         FULL when sig_full = '1' else
                         HIGHS when sig_high = '1' else
                         LIMBO;


end rtl;
