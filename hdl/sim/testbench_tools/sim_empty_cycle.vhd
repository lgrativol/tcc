---------------
-- Libraries --
---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.random_pkg;

------------
-- Entity --
------------

entity sim_empty_cycle is
    generic(
        MEAN            : real     := 1.0;
        WORD_WIDTH      : positive := 8;
        SIDEBAND_WIDTH  : integer  := 0
    );
    port(
        clock           : in std_logic;
        areset          : in std_logic;
        -- Input --
        ready_o         : out std_logic;
        data_valid_i    : in  std_logic;
        data_i          : in  std_logic_vector((WORD_WIDTH - 1) downto 0);
        sideband_i      : in  std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

        -- Output --
        ready_i         : in  std_logic;
        data_valid_o    : out std_logic;
        data_o          : out std_logic_vector((WORD_WIDTH - 1) downto 0);
        sideband_o      : out std_logic_vector((SIDEBAND_WIDTH - 1) downto 0)
); 
end sim_empty_cycle;


architecture simulation_entity of sim_empty_cycle is

    --------------
    -- Signals  --
    --------------

    signal  ready         : std_logic;
    signal  data_valid    : std_logic;
    signal  data          : std_logic_vector((WORD_WIDTH - 1) downto 0);
    signal  sideband      : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

begin

    empty_cycle : process(clock,areset)
    begin
        if (areset = '1') then
            data_valid  <= '0';
        elsif (rising_edge(clock)) then

            if(ready_i = '1') then
                if (random_pkg.random_exp(MEAN) > MEAN ) then
                    ready   <= '0';
                else
                    ready   <= '1';
                end if;
            else
                ready <= '0';
            end if;

            if (ready = '1') then
                
                data_valid <= data_valid_i;

                if(data_valid_i = '1')then
                    data        <= data_i;
                    sideband    <= sideband_i;
                end if;
            end if;
        end if;
    end process;
    
    ready_o         <= ready;
    data_valid_o    <= data_valid;
    data_o          <= data;
    sideband_o      <= sideband;

end architecture simulation_entity;