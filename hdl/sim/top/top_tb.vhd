
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

entity top_tb is
generic
(
  C_S_AXI_DATA_WIDTH             : integer              := 32;
  C_S_AXI_ADDR_WIDTH             : integer              := 32
);

end top_tb;


------------------
-- Architecture --
------------------

architecture testbench of top_tb is

    ---------------
    -- Functions --
    ---------------

    impure function rand_real(min_val, max_val : real) return real is
        variable seed1, seed2 : integer := 999;
        variable r : real;
    begin
        uniform(seed1, seed2, r);
        return r * (max_val - min_val) + min_val;
    end function;

    -----------
    -- Types --
    -----------

    type axi_data_tp                        is array (natural range <>) of std_logic_vector( (C_S_AXI_DATA_WIDTH - 1) downto 0 );

    ---------------
    -- Constants --
    ---------------
    constant CLOCK_PERIOD                 : time := 10 ns;
    constant OUTPUT_WIDTH                 : positive := 10;
    constant WRITE_DATA                   : axi_data_tp(0 to 23) := (   x"0000_0002",       -- wave config (8 bits)
                                                                        x"05F5_E100",       -- sample frequency (27 bits)
                                                                        x"0000_0320",       -- wave nb points (32 bits)
                                                                        x"DEAD_CAFE",       -- empty
                                                                        x"DEAD_CAFE",       -- empty
                                                                        x"DEAD_CAFE",       -- empty
                                                                        x"DEAD_CAFE",       -- empty
                                                                        x"DEAD_CAFE",       -- empty
                                                                        x"0000_0002",       -- fsm nb_repetitions (6 bits)
                                                                        x"0000_0320",       -- fsm tx timer (18 bits)
                                                                        x"0000_000A",       -- fsm deadzone timer (18 bits)
                                                                        x"0000_0320",       -- fsm rx timer (18 bits)
                                                                        x"0000_0004",       -- fsm idle timer (18 bits)
                                                                        x"0000_0004",       -- pulser nb repetitions (10 bits)
                                                                        x"0000_0010",       -- pulser t1 (10 bits)
                                                                        x"0000_0010",       -- pulser t2 (10 bits)
                                                                        x"0000_0010",       -- pulser t3 (10 bits)
                                                                        x"0000_0010",       -- pulser t4 (10 bits)
                                                                        x"0000_0010",       -- pulser tdamp  (10 bits)
                                                                        x"0000_0000",       -- pulser invert/triple (2 bits)
                                                                        x"0040_56FF",       -- DDS phase term (32 bits)
                                                                        x"0000_0000",       -- DDS init phase (32 bits)
                                                                        x"0000_10C8",       -- DDS nb_points / nb_repetitions (20 bits)
                                                                        x"0000_0000"  );    -- DDS mode time (1 bits)
    
    constant WRITE_BASE_ADDRESS         : unsigned      := x"0000_0008";
    constant WORD_FRAC_PART             : integer       := CORDIC_FRAC_PART;

    -------------
    -- Signals --
    -------------
    
    -- TOP TX
    -----AXI
    signal s_axi_aclk                       : std_logic;
    signal s_axi_aresetn                    : std_logic;

    signal s_axi_awready                    : std_logic;
    signal s_axi_awvalid                    : std_logic;
    signal s_axi_awaddr                     : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    signal s_axi_awprot                     : std_logic_vector(2 downto 0);

    signal s_axi_wready                     : std_logic;
    signal s_axi_wvalid                     : std_logic;
    signal s_axi_wstrb                      : std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    signal s_axi_wdata                      : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

    signal s_axi_arready                    : std_logic;
    signal s_axi_arvalid                    : std_logic;
    signal s_axi_araddr                     : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    signal s_axi_arprot                     : std_logic_vector(2 downto 0);

    signal s_axi_rready                     : std_logic;
    signal s_axi_rvalid                     : std_logic;
    signal s_axi_rresp                      : std_logic_vector(1 downto 0);
    signal s_axi_rdata                      : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

    signal s_axi_bready                     : std_logic;
    signal s_axi_bresp                      : std_logic_vector(1 downto 0);
    signal s_axi_bvalid                     : std_logic;

    ----- User
    signal tx_wave_strb_o                      : std_logic;
    signal tx_wave_data                        : std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);
    signal tx_wave_done                        : std_logic;

    signal tx_control_bang                     : std_logic;
    signal tx_control_sample_frequency_strb_o  : std_logic;
    signal tx_control_sample_frequency         : std_logic_vector(26 downto 0); --TBD

    signal tx_control_reset_averager           : std_logic;
    signal tx_control_config_strb_o            : std_logic;
    signal tx_control_nb_points_wave           : std_logic_vector(31 downto 0); -- TBD
    signal tx_control_nb_repetitions_wave      : std_logic_vector(5 downto 0);  -- TBD

    -- TOP RX
    signal rx_wave_strb_i                      : std_logic;
    signal rx_wave_data_i                      : std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);
    signal rx_wave_done_i                      : std_logic;

    signal rx_control_bang                     : std_logic;
    signal rx_control_sample_frequency_strb_i  : std_logic;
    signal rx_control_sample_frequency         : std_logic_vector(26 downto 0); --TBD
    
    signal rx_control_reset_averager           : std_logic;
    signal rx_control_config_strb_i            : std_logic;
    signal rx_control_nb_points_wave           : std_logic_vector(31 downto 0); -- TBD
    signal rx_control_nb_repetitions_wave      : std_logic_vector(5 downto 0);  -- TBD

    signal rx_wave_strb_o                      : std_logic;
    signal rx_wave_data_o                      : std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);
    signal rx_wave_done_o                      : std_logic;

    -- Generic Shift
    signal gsr_strb_i                          : std_logic;
    signal gsr_input_data                      : std_logic_vector((OUTPUT_WIDTH - 1) downto 0);
    signal gsr_sideband_data_i                 : std_logic_vector(0 downto 0);            

    signal gsr_strb_o                          : std_logic;
    signal gsr_output_data                     : std_logic_vector((OUTPUT_WIDTH - 1) downto 0);
    signal gsr_sideband_data_o                 : std_logic_vector(0 downto 0);
    
    -- Testbench
    signal areset                              : std_logic;
    signal noise_data                          : sfixed( 1 downto WORD_FRAC_PART );
    signal sendIt                              : std_logic := '0';
    signal readIt                              : std_logic := '0';

begin

    -- Generate s_axi_aclk signal
    clock_gen : process
    begin
        wait for (CLOCK_PERIOD / 2);
        s_axi_aclk <= '1';
        wait for (CLOCK_PERIOD / 2);
        s_axi_aclk <= '0';
    end process;


    UUT_TX: entity work.top_tx
        generic map(
            OUTPUT_WIDTH                        => OUTPUT_WIDTH,
            AXI_ADDR_WIDTH                      => C_S_AXI_ADDR_WIDTH,
            BASEADDR                            => x"0000_0000"
        )
        port map(
            -- Clock and Reset
            axi_aclk                            => s_axi_aclk,
            axi_aresetn                         => s_axi_aresetn,
    
            -------------------
            -- AXI Interface --
            -------------------
    
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
            -- Output Interface --
            ----------------------
            
            -- Wave
            wave_strb_o                         => tx_wave_strb_o,
            wave_data_o                         => tx_wave_data,
            wave_done_o                         => tx_wave_done,
    
            -- Control
            control_bang_o                      => tx_control_bang,
            
            control_sample_frequency_strb_o     => tx_control_sample_frequency_strb_o,
            control_sample_frequency_o          => tx_control_sample_frequency,
    
            control_reset_averager_o            => tx_control_reset_averager,
            control_config_strb_o               => tx_control_config_strb_o,
            control_nb_points_wave_o            => tx_control_nb_points_wave,
            control_nb_repetitions_wave_o       => tx_control_nb_repetitions_wave
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
    begin
        s_axi_aresetn   <='0';
        sendit          <='0';

        wait for (8 * CLOCK_PERIOD);
        wait until rising_edge(s_axi_aclk);
            
        s_axi_aresetn   <='1';

        for idx in WRITE_DATA'range loop

            s_axi_awaddr    <= std_logic_vector(WRITE_BASE_ADDRESS + (idx * 4));
            s_axi_wdata     <= WRITE_DATA(idx);
            s_axi_wstrb     <= x"F";
            sendit          <='1';   -- start axi write to slave
            wait for (CLOCK_PERIOD);
            wait until rising_edge(s_axi_aclk);        
            sendit<='0'; --clear start send flag
    
            wait until s_axi_bvalid = '1';
            wait until s_axi_bvalid = '0';  --axi write finished

        end loop;

        s_axi_awaddr    <= x"0000_0004";
        s_axi_wdata     <= x"0000_0001";
        s_axi_wstrb     <= x"F";
        sendit          <='1';   -- start axi write to slave
        wait for (CLOCK_PERIOD);
        wait until rising_edge(s_axi_aclk);        
        sendit<='0'; --clear start send flag

        wait until s_axi_bvalid = '1';
        wait until s_axi_bvalid = '0';  --axi write finished

        wait until tx_control_reset_averager = '1';
        wait until rising_edge(s_axi_aclk);

        -- s_axi_awaddr    <= x"0000_002C";
        -- s_axi_wdata     <= x"0000_0110";
        -- s_axi_wstrb     <= x"F";
        -- sendit          <='1';   -- start axi write to slave
        -- wait for (CLOCK_PERIOD);
        -- wait until rising_edge(s_axi_aclk);        
        -- sendit<='0'; --clear start send flag

        -- wait until s_axi_bvalid = '1';
        -- wait until s_axi_bvalid = '0';  --axi write finished        
        
        -- s_axi_awaddr    <= x"0000_0008";
        -- s_axi_wdata     <= x"0000_0001";
        -- s_axi_wstrb     <= x"F";
        -- sendit          <='1';   -- start axi write to slave
        -- wait for (CLOCK_PERIOD);
        -- wait until rising_edge(s_axi_aclk);        
        -- sendit<='0'; --clear start send flag

        -- wait until s_axi_bvalid = '1';
        -- wait until s_axi_bvalid = '0';  --axi write finished       

        -- s_axi_awaddr    <= x"0000_0004";
        -- s_axi_wdata     <= x"0000_0001";
        -- s_axi_wstrb     <= x"F";
        -- sendit          <='1';   -- start axi write to slave
        -- wait for (CLOCK_PERIOD);
        -- wait until rising_edge(s_axi_aclk);        
        -- sendit<='0'; --clear start send flag

        -- wait until s_axi_bvalid = '1';
        -- wait until s_axi_bvalid = '0';  --axi write finished       

        -- s_axi_araddr<=x"0";
        -- readit<='1';                --start axi read from slave
        -- wait for 1 ns; 
        -- readit<='0'; --clear "start read" flag

        -- wait until s_axi_rvalid = '1';
        -- wait until s_axi_rvalid = '0';

        -- s_axi_araddr    <=x"4";
        -- readit          <='1';                --start axi read from slave
        -- wait for 1 ns; 
        -- readit          <='0'; --clear "start read" flag

        -- wait until s_axi_rvalid = '1';
        -- wait until s_axi_rvalid = '0';
            
        wait; -- will wait forever
    end process;

    areset <= not s_axi_aresetn;

    ----------------
    -- Delay line --
    ----------------

    --noise_data <= resize(to_sfixed(tx_wave_data,noise_data) + to_sfixed(rand_real(-0.2,0.2),noise_data),noise_data); 

    gsr_strb_i              <= tx_wave_strb_o;
    --gsr_input_data          <= to_slv(noise_data);
    gsr_input_data          <= tx_wave_data;
    gsr_sideband_data_i(0)  <= tx_wave_done;

    GSR : entity work.generic_shift_reg 
        generic map(
            WORD_WIDTH                          => OUTPUT_WIDTH,
            SHIFT_SIZE                          => 8,
            SIDEBAND_WIDTH                      => 1
        )
        port map(
            -- Clock interface
            clock_i                             => s_axi_aclk,
            areset_i                            => areset,
            -- Input interface
            strb_i                              => gsr_strb_i,
            input_data_i                        => gsr_input_data,
            sideband_data_i                     => gsr_sideband_data_i,
            
            -- Output interface
            strb_o                              => gsr_strb_o,
            output_data_o                       => gsr_output_data,
            sideband_data_o                     => gsr_sideband_data_o
        );

    ------------
    -- TOP RX --
    ------------

    rx_wave_strb_i                      <= gsr_strb_o;
    rx_wave_data_i                      <= gsr_output_data;
    rx_wave_done_i                      <= gsr_sideband_data_o(0);
    
    rx_control_sample_frequency_strb_i  <= tx_control_sample_frequency_strb_o;
    rx_control_sample_frequency         <= tx_control_sample_frequency;

    rx_control_reset_averager           <= tx_control_reset_averager;
    rx_control_config_strb_i            <= tx_control_config_strb_o;
    rx_control_nb_points_wave           <= tx_control_nb_points_wave;
    rx_control_nb_repetitions_wave      <= tx_control_nb_repetitions_wave;

    UUT_RX : entity work.top_rx
        generic map(
            OUTPUT_WIDTH                        => OUTPUT_WIDTH
        )
        port map(

            clock_i                             => s_axi_aclk,
            areset_i                            => areset,
    
            -- Wave
            wave_strb_i                         => rx_wave_strb_i,
            wave_data_i                         => rx_wave_data_i,
            wave_done_i                         => rx_wave_done_i,
    
            -- Control
            control_sample_frequency_strb_i     => rx_control_sample_frequency_strb_i,
            control_sample_frequency_i          => rx_control_sample_frequency,
    
            --control_start_rx_i                  => rx_control_start_rx,
            control_reset_averager_i            => rx_control_reset_averager,
            control_config_strb_i               => rx_control_config_strb_i,
            control_nb_points_wave_i            => rx_control_nb_points_wave,
            control_nb_repetitions_wave_i       => rx_control_nb_repetitions_wave,

            wave_strb_o                         => rx_wave_strb_o,
            wave_data_o                         => rx_wave_data_o,
            wave_done_o                         => rx_wave_done_o
        );



end testbench;
