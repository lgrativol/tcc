---------------
-- Libraries --
---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

------------
-- Entity --
------------

entity generic_shift_reg is
    generic (
        WORD_WIDTH                          : positive := 4;
        SHIFT_SIZE                          : integer  := 0;
        SIDEBAND_WIDTH                      : natural  := 0
    );
    port (
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset
        -- Input interface
        strb_i                              : in  std_logic; -- Valid in
        input_data_i                        : in  std_logic_vector((WORD_WIDTH - 1) downto 0);
        sideband_data_i                     : in  std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
        
        -- Output interface
        strb_o                              : out std_logic;
        output_data_o                       : out std_logic_vector((WORD_WIDTH - 1) downto 0);
        sideband_data_o                     : out std_logic_vector((SIDEBAND_WIDTH - 1) downto 0)
    );
end generic_shift_reg;

------------------
-- Architecture --
------------------
architecture behavioral of generic_shift_reg is

    -----------
    -- Types --
    -----------

    type t_shift_reg_strb       is array (integer range <>) of std_logic;
    type t_shift_reg_data       is array (integer range <>) of std_logic_vector((WORD_WIDTH - 1) downto 0);
    type t_shift_reg_sideband   is array (integer range <>) of std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

    -------------
    -- Signals --
    -------------
    
    -- Stage 0
    signal      strb_in                         : std_logic;
    signal      input_data                      : std_logic_vector((WORD_WIDTH - 1) downto 0);
    signal      sideband_data_in                : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
    signal      enable_shift                    : std_logic;

    -- Stage 1

    signal      shift_reg_strb                  : t_shift_reg_strb      (0 to (SHIFT_SIZE - 1));
    signal      shift_reg_data                  : t_shift_reg_data      (0 to (SHIFT_SIZE - 1));
    signal      shift_reg_sideband              : t_shift_reg_sideband  (0 to (SHIFT_SIZE - 1));

begin


    -------------
    -- Stage 0 --
    -------------
    
    strb_in           <=strb_i;
    input_data        <=input_data_i;
    sideband_data_in  <=sideband_data_i;

    NO_SHIFT_GEN: 
        if (SHIFT_SIZE <= 0) generate

            ------------
            -- Output --
            ------------

            strb_o          <= strb_in;
            output_data_o   <= input_data;
            sideband_data_o <= sideband_data_in;

        end generate NO_SHIFT_GEN;

    SHIFT_GEN: 
        if (SHIFT_SIZE > 0) generate    

            --------------
            -- Stage 1  --
            --------------
            enable_shift    <=          strb_in
                                    or  shift_reg_strb     (SHIFT_SIZE - 1);
            shift_reg_proc : process(clock_i,areset_i)
            begin
                if(areset_i ='1') then
                    shift_reg_strb    <= (others=>'0');

                elsif(rising_edge(clock_i)) then

                    shift_reg_strb(0)    <= strb_in;

                    for index in 1 to  (SHIFT_SIZE - 1) loop

                        shift_reg_strb(index)    <= shift_reg_strb(index - 1) ;
                    end loop;

                    if (enable_shift = '1') then

                        shift_reg_data(0)       <= input_data;    
                        shift_reg_sideband(0)   <= sideband_data_in;    

                        for index in 1 to  (SHIFT_SIZE - 1) loop

                            shift_reg_data(index)       <= shift_reg_data(index - 1) ;
                            shift_reg_sideband(index)   <= shift_reg_sideband(index - 1) ;
                        end loop;    
                    end if;
                end if;
            end process;
            

            ------------
            -- Output --
            ------------
            strb_o              <= shift_reg_strb     (SHIFT_SIZE - 1);
            output_data_o       <= shift_reg_data     (SHIFT_SIZE - 1);
            sideband_data_o     <= shift_reg_sideband (SHIFT_SIZE - 1);

        end generate SHIFT_GEN;

    end behavioral;
