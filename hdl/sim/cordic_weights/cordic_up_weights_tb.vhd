-------------
-- Library --
-------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library ieee_proposed;                      
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all; 

library work;
use work.utils_pkg.all;

------------
-- Entity --
------------

entity cordic_up_weights_tb is
end cordic_up_weights_tb;


------------------
-- Architecture --
------------------

architecture testbench of cordic_up_weights_tb is

   
    ---------------
    -- Constants --
    ---------------

    constant PHASE_FRAC_PART              : integer       := -27; 
    constant CORDIC_INTEGER_PART          : natural       := 1;
    constant CORDIC_FRAC_PART             : integer       := -8;

    constant PI_INTEGER_PART              : integer       := 4; 
    constant PI_FRAC_PART                 : integer       := -27;

    constant PI                           : ufixed(PI_INTEGER_PART downto PI_FRAC_PART) := to_ufixed(MATH_PI, PI_INTEGER_PART,PI_FRAC_PART);
    constant WEIGHTS_WIDTH                : positive      := 16;
    constant CLOCK_PERIOD                 : time          := 10 ns;
    constant OUTPUT_WIDTH                 : positive      := 10;                                                                      
    constant WRITE_BASE_ADDRESS           : unsigned      := x"0000_000C";
    constant WORD_FRAC_PART               : integer       := CORDIC_FRAC_PART;
    constant RAM_DEPTH                    : positive      := 65536;
    constant RAM_DATA_WIDTH               : positive      := OUTPUT_WIDTH + 1;
    constant MAX_ADDR_WIDTH               : positive      := ceil_log2(RAM_DEPTH + 1); 
    constant C_S_AXI_ADDR_WIDTH           : positive      := 32;
    constant C_S_AXI_DATA_WIDTH           : positive      := 32;

    -----------
    -- Types --
    -----------
    type axi_data_tp                        is array (natural range <>) of std_logic_vector( (C_S_AXI_DATA_WIDTH - 1) downto 0 );
    type weights_tp                         is array (natural range <>) of std_logic_vector( (WEIGHTS_WIDTH - 1) downto 0 );

    constant WEIGHTS                        : weights_tp(0 to 9) := ( x"00EE",
                                                                      x"042D",   
                                                                      x"0A71",   
                                                                      x"1218",   
                                                                      x"177D",   
                                                                      x"177D",   
                                                                      x"1218",   
                                                                      x"0A71",   
                                                                      x"042D",   
                                                                      x"00EE");


    ---------------
    -- Functions --
    ---------------

    function    gen_dds( nb_periods         : positive;
                         freq               : positive;
                         conv_rate          : positive)
                return axi_data_tp is

            constant    one_nb_points         : positive                      :=  (100e6/freq);
            constant    shift_left            : real                          := real(2**(-PHASE_FRAC_PART));
            constant    delta                 : positive                      := integer(((2.0 * MATH_PI) / real(one_nb_points) ) *shift_left );

            constant    wave_nb_periods       : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(nb_periods,32));
            constant    sampler_rate          : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(conv_rate,32));
            constant    phase_term            : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(delta,32)); 
            constant    dds_nb_points         : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(one_nb_points,32)); 

            constant WRITE_DATA               : axi_data_tp(0 to 14) := (   wave_nb_periods,        -- wave nb periods (8 bits) 0xc
                                                                            x"DEAD_CAFE",           -- empty 0x10
                                                                            sampler_rate,           -- conv_rate
                                                                            x"0000" & WEIGHTS(0),   -- weights(0) 0x18
                                                                            x"0000" & WEIGHTS(1),   -- weights(1)
                                                                            x"0000" & WEIGHTS(2),   -- weights(2)
                                                                            x"0000" & WEIGHTS(3),   -- weights(3)
                                                                            x"0000" & WEIGHTS(4),   -- weights(4)
                                                                            x"0000" & WEIGHTS(5),   -- weights(5)
                                                                            x"0000" & WEIGHTS(6),   -- weights(6)
                                                                            x"0000" & WEIGHTS(7),   -- weights(7)
                                                                            x"0000" & WEIGHTS(8),   -- weights(8)
                                                                            x"0000" & WEIGHTS(9),   -- weights(9)
                                                                            phase_term,             -- DDS phase term 
                                                                            dds_nb_points       );  -- DDS nb_points
    begin
        return WRITE_DATA;
    end function gen_dds;

    -------------
    -- Signals --
    -------------
    
    --AXI-Lite TX
    signal s_axi_aclk                       : std_logic;
    signal s_axi_aresetn                    : std_logic;

    signal s_axi_awready                    : std_logic;
    signal s_axi_awvalid                    : std_logic;
    signal s_axi_awaddr                     : std_logic_vector((C_S_AXI_ADDR_WIDTH - 1) downto 0);
    signal s_axi_awprot                     : std_logic_vector(2 downto 0);

    signal s_axi_wready                     : std_logic;
    signal s_axi_wvalid                     : std_logic;
    signal s_axi_wstrb                      : std_logic_vector(((C_S_AXI_DATA_WIDTH / 8) - 1) downto 0);
    signal s_axi_wdata                      : std_logic_vector((C_S_AXI_DATA_WIDTH - 1) downto 0);

    signal s_axi_arready                    : std_logic;
    signal s_axi_arvalid                    : std_logic;
    signal s_axi_araddr                     : std_logic_vector((C_S_AXI_ADDR_WIDTH - 1) downto 0);
    signal s_axi_arprot                     : std_logic_vector(2 downto 0);

    signal s_axi_rready                     : std_logic;
    signal s_axi_rvalid                     : std_logic;
    signal s_axi_rresp                      : std_logic_vector(1 downto 0);
    signal s_axi_rdata                      : std_logic_vector((C_S_AXI_DATA_WIDTH - 1) downto 0);

    signal s_axi_bready                     : std_logic;
    signal s_axi_bresp                      : std_logic_vector(1 downto 0);
    signal s_axi_bvalid                     : std_logic;

    --UPsampler wave out
    signal up_output_wave_valid             : std_logic;
    signal up_output_wave_data              : std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);
    signal up_output_wave_done              : std_logic;

    signal sfixed_out_wave_data             : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

    -- Testbench
    signal areset                           : std_logic;

    signal sendIt                           : std_logic := '0';
    signal readIt                           : std_logic := '0';

begin

    -- Generate s_axi_aclk signal
    clock_gen : process
    begin
        wait for (CLOCK_PERIOD / 2);
        s_axi_aclk <= '1';
        wait for (CLOCK_PERIOD / 2);
        s_axi_aclk <= '0';
    end process;

    UUT: entity work.cordic_up_weights
        generic map(
            OUTPUT_WIDTH                        => OUTPUT_WIDTH,
            RAM_DEPTH                           => RAM_DEPTH,
            WEIGHT_WIDTH                        => WEIGHTS_WIDTH,
            AXI_ADDR_WIDTH                      => C_S_AXI_ADDR_WIDTH,
            BASEADDR                            => x"0000_0000"
        )
        port map(
            -- Clock and Reset
            axi_aclk                            => s_axi_aclk,
            axi_aresetn                         => s_axi_aresetn,
    
            -----------------------------
            -- TX - AXI Lite Interface --
            -----------------------------
    
            -- AXI Write Address Channel
            s_axi_awaddr                        => s_axi_awaddr,
            s_axi_awprot                        => s_axi_awprot,
            s_axi_awvalid                       => s_axi_awvalid,
            s_axi_awready                       => s_axi_awready,
            -- AXI Write Data Channel
            s_axi_wdata                         => s_axi_wdata,
            s_axi_wstrb                         => s_axi_wstrb,
            s_axi_wvalid                        => s_axi_wvalid,
            s_axi_wready                        => s_axi_wready,
            -- AXI Read Address Channel
            s_axi_araddr                        => s_axi_araddr,
            s_axi_arprot                        => s_axi_arprot,
            s_axi_arvalid                       => s_axi_arvalid,
            s_axi_arready                       => s_axi_arready,
            -- AXI Read Data Channel
            s_axi_rdata                         => s_axi_rdata,
            s_axi_rready                        => s_axi_rready,
            s_axi_rresp                         => s_axi_rresp,
            s_axi_rvalid                        => s_axi_rvalid,
            -- AXI Write Response Channel
            s_axi_bresp                         => s_axi_bresp,
            s_axi_bvalid                        => s_axi_bvalid,
            s_axi_bready                        => s_axi_bready,

            ----------------------
            -- UP - Wave Output --
            ----------------------
            up_wave_valid_o                     => up_output_wave_valid,
            up_wave_data_o                      => up_output_wave_data,
            up_wave_done_o                      => up_output_wave_done
        );

    -- Initiate process which simulates a master wanting to write.
    -- This process is blocked on a "Send Flag" (sendIt).
    -- When the flag goes to 1, the process exits the wait state and
    -- execute a write transaction.

    send : process
    begin
        s_axi_awvalid       <='0';
        s_axi_wvalid        <='0';
        s_axi_bready        <='0';
        loop
            wait until      sendit     = '1';
            wait until rising_edge(s_axi_aclk);
            s_axi_awvalid       <= '1';
            s_axi_wvalid        <= '1';
            wait until (s_axi_awready and s_axi_wready) = '1';  --client ready to read address/data        
                
            s_axi_bready    <='1';
            
            wait until s_axi_bvalid = '1';  -- write result valid
            assert s_axi_bresp = "11" 
            report "axi data not written" severity warning;

            s_axi_awvalid   <='0';
            s_axi_wvalid    <='0';
            s_axi_bready    <='1';
            
            wait until s_axi_bvalid = '0';  -- all finished
                s_axi_bready    <='0';
        end loop;
    end process;

    -- Initiate process which simulates a master wanting to read.
    -- This process is blocked on a "Read Flag" (readIt).
    -- When the flag goes to 1, the process exits the wait state and
    -- execute a read transaction.
    read : process
    begin
    s_axi_arvalid   <='0';
    s_axi_rready    <='0';

        loop
            wait until readit = '1';
            wait until rising_edge(s_axi_aclk);

            s_axi_arvalid  <='1';
            s_axi_rready   <='1';

            wait until (s_axi_rvalid and s_axi_arready) = '1';  --client provided data

            assert s_axi_rresp = "11" 
            report "axi data not written" severity warning;
            
            s_axi_arvalid   <='0';
            s_axi_rready    <='0';
        end loop;
    end process;

    stim_proc : process
        procedure write_memory  (   constant write_data : in axi_data_tp ) is
        begin

            for idx in write_data'range loop
                s_axi_awaddr    <= std_logic_vector(WRITE_BASE_ADDRESS + (idx * 4));
                s_axi_wdata     <= write_data(idx);
                s_axi_wstrb     <= x"F";
                sendit          <='1';   -- start axi write to slave
                wait for (CLOCK_PERIOD);
                wait until rising_edge(s_axi_aclk);        
                sendit  <='0'; --clear start send flag
        
                wait until s_axi_bvalid = '1';
                wait until s_axi_bvalid = '0';  --axi write finished
            end loop;
                
        end procedure write_memory;

        procedure bang( delay : positive ) is
        begin

            s_axi_awaddr    <= x"0000_0004";
            s_axi_wdata     <= x"0000_0001";
            s_axi_wstrb     <= x"F";
            sendit          <='1';   -- start axi write to slave
            wait for (CLOCK_PERIOD);
            wait until rising_edge(s_axi_aclk);        
            sendit<='0'; --clear start send flag
            
            wait until s_axi_bvalid = '1';
            wait until s_axi_bvalid = '0';  --axi write finished
        end procedure bang;

        variable data                           : axi_data_tp(0 to 14);

    begin
        s_axi_aresetn   <='0';
        sendit          <='0';

        wait for (8 * CLOCK_PERIOD);
        wait until rising_edge(s_axi_aclk);
        s_axi_aresetn   <='1';

        -- gen_dds(nb_periods,freq,conv_rate)
        data := gen_dds(2,500e3,4);           
        write_memory(data);
        bang(1);

        wait;
    end process;

    --------------------
    -- To file output --
    --------------------

    sfixed_out_wave_data <= to_sfixed(up_output_wave_data,sfixed_out_wave_data);

    write2file : entity work.sim_write2file
        generic map (
            FILE_NAME    => "./output_cordic_up_weights.txt", 
            INPUT_WIDTH  => OUTPUT_WIDTH
        )
        port map (
            clock           => s_axi_aclk,
            hold            => '0',
            data_valid      => up_output_wave_valid,
            data_in         => up_output_wave_data
        ); 
end architecture;