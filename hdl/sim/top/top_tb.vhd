
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
use work.defs_pkg.all;

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

    -----------
    -- Types --
    -----------

    type axi_data_tp                        is array (natural range <>) of std_logic_vector( (C_S_AXI_DATA_WIDTH - 1) downto 0 );

    ---------------
    -- Constants --
    ---------------
    constant CLOCK_PERIOD                 : time          := 10 ns;
    constant OUTPUT_WIDTH                 : positive      := 10;                                                                      
    constant WRITE_BASE_ADDRESS           : unsigned      := x"0000_000C";
    constant WORD_FRAC_PART               : integer       := CORDIC_FRAC_PART;
    constant RAM_DEPTH                    : positive      := 65536;
    constant RAM_DATA_WIDTH               : positive      := OUTPUT_WIDTH + 1;
    constant MAX_ADDR_WIDTH               : positive      := ceil_log2(RAM_DEPTH + 1); 


    ---------------
    -- Functions --
    ---------------

    function    gen_dds( nb_periods         : positive;
                         nb_repetitions     : positive;
                         freq               : positive;
                         init_phase         : real; 
                         mode_time          : std_logic)
                return axi_data_tp is

            constant    one_nb_points         : positive                      :=  (100e6/freq);
            constant    nb_points             : positive                      :=  (one_nb_points * nb_periods);
            constant    setup                 : positive                      :=  100;
            constant    deadzone              : positive                      :=  500;
            constant    idle                  : positive                      :=  100;
            constant    shift_left            : real                          := real(2**(-PHASE_FRAC_PART));
            constant    delta                 : positive                      := integer(((2.0 * MATH_PI) / real(one_nb_points) ) *shift_left );
            constant    phase                 : natural                       := integer((init_phase) * shift_left);

            constant    wave_nb_periods       : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(nb_periods,32));
            constant    wave_nb_points        : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(nb_points,32));
            constant    wave_nb_repts         : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(nb_repetitions,32));
            constant    setup_time            : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(setup,32));
            constant    tx_time               : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(deadzone + nb_points,32)); 
            constant    deadzone_time         : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(deadzone,32)); 
            constant    rx_time               : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(nb_points,32)); 
            constant    idle_time             : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(idle,32)); 
            constant    phase_term            : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(delta,32)); 
            constant    dds_nb_points         : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(one_nb_points,32)); 
            constant    dds_init_phase        : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(phase,32)); 
            constant    mode                  : std_logic_vector(31 downto 0) := (0 => mode_time, others => '0');

            constant WRITE_DATA               : axi_data_tp(0 to 21) := (   wave_nb_periods,    -- wave nb periods (8 bits) 0xc
                                                                            wave_nb_points,     -- wave nb points (32 bits) 0x10
                                                                            x"0000_0000",       -- wave config (1 bits) 0x14
                                                                            x"DEAD_CAFE",       -- empty 0x18
                                                                            x"DEAD_CAFE",       -- empty 0x1c
                                                                            x"DEAD_CAFE",       -- empty 0x20
                                                                            wave_nb_repts,      -- fsm nb_repetitions (6 bits)
                                                                            setup_time,         -- fsm setup timer (18 bits)
                                                                            tx_time,            -- fsm tx timer (18 bits)
                                                                            deadzone_time,      -- fsm deadzone timer (18 bits)
                                                                            rx_time,            -- fsm rx timer (18 bits)
                                                                            idle_time,          -- fsm idle timer (18 bits)
                                                                            x"0000_0000",       -- pulser t1 (10 bits)
                                                                            x"0000_0000",       -- pulser t2 (10 bits)
                                                                            x"0000_0000",       -- pulser t3 (10 bits)
                                                                            x"0000_0000",       -- pulser t4 (10 bits)
                                                                            x"0000_0000",       -- pulser t5  (10 bits)
                                                                            x"0000_0000",       -- pulser invert/triple (2 bits)
                                                                            phase_term,         -- DDS phase term (32 bits)
                                                                            dds_nb_points,      -- DDS nb points (18 bits)
                                                                            dds_init_phase,     -- DDS init phase (32 bits)
                                                                            mode          );    -- DDS mode time (1 bits)
    begin
        return WRITE_DATA;
    end function gen_dds;

    function    gen_pulser( nb_periods         : positive;
                            nb_repetitions     : positive;
                            t1                 : positive;
                            t2                 : positive;
                            t3                 : positive;
                            t4                 : positive;
                            t5                 : positive;
                            inverted           : std_logic;
                            triple             : std_logic )
                return axi_data_tp is

            constant    nb_points             : positive                      :=  ( (t1 + t2 + t3 + t4) * nb_periods) + t5;
            constant    deadzone              : positive                      :=  500;
            constant    idle                  : positive                      :=  100;

            constant    wave_nb_periods       : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(nb_periods,32));
            constant    wave_nb_points        : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(nb_points,32));
            constant    wave_nb_repts         : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(nb_repetitions,32));
            constant    setup_time            : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(100,32));
            constant    tx_time               : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(deadzone + nb_points,32)); 
            constant    deadzone_time         : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(deadzone,32)); 
            constant    rx_time               : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(nb_points,32)); 
            constant    idle_time             : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(idle,32)); 
            constant    pulser_t1             : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(t1,32)); 
            constant    pulser_t2             : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(t2,32)); 
            constant    pulser_t3             : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(t3,32)); 
            constant    pulser_t4             : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(t4,32)); 
            constant    pulser_t5             : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(t5,32)); 
            constant    pulser_mode           : std_logic_vector(31 downto 0) := (1 => inverted, 0 =>triple,  others => '0');

            constant WRITE_DATA               : axi_data_tp(0 to 21) := (   wave_nb_periods,    -- wave nb periods (8 bits) 0xc
                                                                            wave_nb_points,     -- wave nb points (32 bits) 0x10
                                                                            x"0000_0001",       -- wave config (1 bits) 0x14
                                                                            x"DEAD_CAFE",       -- empty 0x18
                                                                            x"DEAD_CAFE",       -- empty 0x1c
                                                                            x"DEAD_CAFE",       -- empty 0x20
                                                                            wave_nb_repts,      -- fsm nb_repetitions (6 bits)
                                                                            setup_time,         -- fsm setup timer (18 bits)
                                                                            tx_time,            -- fsm tx timer (18 bits)
                                                                            deadzone_time,      -- fsm deadzone timer (18 bits)
                                                                            rx_time,            -- fsm rx timer (18 bits)
                                                                            idle_time,          -- fsm idle timer (18 bits)
                                                                            pulser_t1,          -- pulser t1 (10 bits)
                                                                            pulser_t2,          -- pulser t2 (10 bits)
                                                                            pulser_t3,          -- pulser t3 (10 bits)
                                                                            pulser_t4,          -- pulser t4 (10 bits)
                                                                            pulser_t5,          -- pulser t5  (10 bits)
                                                                            x"0000_0000",       -- pulser invert/triple (2 bits)
                                                                            x"0000_0000",       -- DDS phase term (32 bits)
                                                                            x"0000_0000",       -- DDS nb points (18 bits)
                                                                            x"0000_0000",       -- DDS init phase (32 bits)
                                                                            x"0000_0000"          );    -- DDS mode time (1 bits)
    begin
        return WRITE_DATA;
    end function gen_pulser;

    -------------
    -- Signals --
    -------------
    
    -- TOP
    -----AXI-Lite TX
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

    ----Wave out TX
    signal tx_output_wave_valid             : std_logic;
    signal tx_output_wave_data              : std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);
    signal tx_output_wave_done              : std_logic;

    ----Wave in RX
    signal rx_input_wave_valid              : std_logic;
    signal rx_input_wave_data               : std_logic_vector((OUTPUT_WIDTH - 1) downto 0);
   -- signal rx_input_wave_done               : std_logic;

    ----AXI-Stream RX
    signal s_axis_s2mm_0_tready             : std_logic;
    signal s_axis_s2mm_0_tvalid             : std_logic;
    signal s_axis_s2mm_0_tdata              : std_logic_vector ( (C_S_AXI_DATA_WIDTH - 1) downto 0 );
    signal s_axis_s2mm_0_tkeep              : std_logic_vector ( ((C_S_AXI_DATA_WIDTH / 8) - 1) downto 0 );
    signal s_axis_s2mm_0_tlast              : std_logic;

    -- Ring FIFO
    signal fifo_config_input_valid          : std_logic;
    signal fifo_config_max_addr             : std_logic_vector( ( MAX_ADDR_WIDTH - 1 ) downto 0 );
    signal config_reset_pointers_i          : std_logic;
    
    signal fifo_wr_input_valid              : std_logic;
    signal fifo_wr_data                     : std_logic_vector( (RAM_DATA_WIDTH - 1) downto 0);
       
    signal fifo_rd_en                       : std_logic;
    signal fifo_rd_en_reg                   : std_logic:='0';
    signal fifo_output_valid                : std_logic;
    signal fifo_rd_data                     : std_logic_vector( (RAM_DATA_WIDTH - 1) downto 0);
    
    signal fifo_full                        : std_logic;

    -- Testbench
    signal areset                           : std_logic;
    signal delay                            : positive;
    signal counter_fifo_enable              : natural;

    signal sfixed_tx_output_wave_data       : sfixed(1 downto WORD_FRAC_PART);
    signal sfixed_axist_data                : sfixed(1 downto WORD_FRAC_PART);

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

    s_axis_s2mm_0_tready    <= '1';

    UUT: entity work.top
        generic map(
            OUTPUT_WIDTH                        => OUTPUT_WIDTH,
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
            -- TX - Wave Output --
            ----------------------
            tx_wave_valid_o                     => tx_output_wave_valid,
            tx_wave_data_o                      => tx_output_wave_data,
            tx_wave_done_o                      => tx_output_wave_done,

            ---------------------
            -- RX - Wave Input --
            ---------------------
            rx_wave_valid_i                     => rx_input_wave_valid,
            rx_wave_data_i                      => rx_input_wave_data,
            --rx_wave_done_i                      => rx_input_wave_done,
    
        -------------------------------
        -- RX - AXI Stream Interface --
        -------------------------------
            s_axis_s2mm_0_tready                => s_axis_s2mm_0_tready,
            s_axis_s2mm_0_tvalid                => s_axis_s2mm_0_tvalid,
            s_axis_s2mm_0_tdata                 => s_axis_s2mm_0_tdata,
            s_axis_s2mm_0_tkeep                 => s_axis_s2mm_0_tkeep,
            s_axis_s2mm_0_tlast                 => s_axis_s2mm_0_tlast
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

            fifo_config_input_valid                     <= '1';
            fifo_config_max_addr                        <= std_logic_vector(to_unsigned(delay - 1,fifo_config_max_addr'length));
            wait for (CLOCK_PERIOD);
            wait until rising_edge(s_axi_aclk);   
            
            fifo_config_input_valid                     <= '0';
            wait for (CLOCK_PERIOD);
            wait until rising_edge(s_axi_aclk);   

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

        variable data                           : axi_data_tp(0 to 21);

    begin
        s_axi_aresetn   <='0';
        sendit          <='0';

        wait for (8 * CLOCK_PERIOD);
        wait until rising_edge(s_axi_aclk);
        s_axi_aresetn   <='1';

        -- gen_dds(nb_periods,nb_repetitions,freq,init_phase,mode_time)
        data := gen_dds(4,4,500e3,0.0,'0');   
        delay <= to_integer(unsigned(data(8)));

        wait for (CLOCK_PERIOD);
        wait until rising_edge(s_axi_aclk); 
        
        write_memory(data);
        bang(delay);

        wait for (20*CLOCK_PERIOD);
        wait until rising_edge(s_axi_aclk); 
        s_axi_awaddr    <= x"0000_0004";
        s_axi_wdata     <= x"0000_0001";
        s_axi_wstrb     <= x"F";
        sendit          <='1';   -- start axi write to slave
        wait for (CLOCK_PERIOD);
        wait until rising_edge(s_axi_aclk);        
        sendit<='0'; --clear start send flag
        
        wait until s_axi_bvalid = '1';
        wait until s_axi_bvalid = '0';  --axi write finished

        wait until s_axis_s2mm_0_tvalid = '1' and s_axis_s2mm_0_tlast = '1';
        wait for (CLOCK_PERIOD);
        wait until  rising_edge(s_axi_aclk); 

        -- gen_pulser(nb_periods,nb_repetitions,t1,t2,t3,t4,t5,inverted,triple)
        data := gen_pulser(3,4,50,25,17,18,36,'0','0');   
        delay <= to_integer(unsigned(data(8)));
        
        write_memory(data);
        bang(delay);

        wait;
    end process;

    areset <= not s_axi_aresetn;

    sfixed_tx_output_wave_data  <= to_sfixed(tx_output_wave_data,sfixed_tx_output_wave_data);
    sfixed_axist_data           <= to_sfixed(s_axis_s2mm_0_tdata((OUTPUT_WIDTH - 1) downto 0),sfixed_axist_data);

    ----------------
    -- Delay line --
    ----------------

    fifo_wr_input_valid                         <= tx_output_wave_valid;
    fifo_wr_data(OUTPUT_WIDTH downto  1)        <= tx_output_wave_data;
    fifo_wr_data(0)                             <= tx_output_wave_done;

    deadzone_ent: entity work.ring_fifo
        generic map (
            DATA_WIDTH                  => RAM_DATA_WIDTH,
            RAM_DEPTH                   => RAM_DEPTH
        )
        port map (
            clock_i                     => s_axi_aclk,
            areset_i                    => areset,

            -- Config  port
            config_valid_i              => fifo_config_input_valid,
            config_max_addr_i           => fifo_config_max_addr,
            config_reset_pointers_i     => config_reset_pointers_i,

            -- Write port
            wr_valid_i                  => fifo_wr_input_valid,
            wr_data_i                   => fifo_wr_data,

            -- Read port
            rd_en_i                     => fifo_rd_en,
            rd_valid_o                  => fifo_output_valid, 
            rd_data_o                   => fifo_rd_data, 

            -- Flags
            empty                       => open,
            full                        => fifo_full
        );

    fifo_rd_en_proc : process(s_axi_aclk) 
    begin
        if (rising_edge(s_axi_aclk)) then
            if (tx_output_wave_valid = '1' or (counter_fifo_enable > 0 and fifo_rd_data(0) /= '1')) then
                if(counter_fifo_enable = (delay - 1)) then
                    fifo_rd_en <= '1';
                else
                    fifo_rd_en <= '0';
                    counter_fifo_enable <= counter_fifo_enable + 1;
                end if;
            else
                fifo_rd_en <= '0';
                counter_fifo_enable <= 0;
            end if;

            fifo_rd_en_reg <= fifo_rd_en;
        end if;
    end process;

    config_reset_pointers_i <=          fifo_rd_en_reg
                                    and not(fifo_rd_en);
    
    rx_input_wave_valid     <= fifo_output_valid;
    rx_input_wave_data      <= fifo_rd_data(OUTPUT_WIDTH downto 1);
    --rx_input_wave_done      <= fifo_rd_data(0);
    
end testbench;