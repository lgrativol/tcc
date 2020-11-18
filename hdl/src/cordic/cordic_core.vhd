---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Agosto/2020                                                                
-- Module Name: cordic_core                                                                
-- Author Name: Versão original Felipe Calliari, update: Lucas Grativol Ribeiro            
--                                                                                         
-- Revision Date: 18/11/2020                                                               
-- Tool version: Vivado 2017.4                                                             
--                                                                                         
-- Goal: Calcular seno e cosseno de um dado ângulo "z".                                    
-- Description:  Instancia os cordic_slices, cada slice implementa em si uma iteração      
--               do algoritmo CORDIC versão rotacional.                                    
--               Para gerar (seno,cosseno): 
--
--               Input (x_i,y_i,z_i) -> (0,607253;0;ângulo)
--               Output (x_o,y_o,z_o) -> (cos(ânngulo),seno(ângulo),~ 0)
--                                                                                 
--               Obs.(1): Algoritmo só converge para ângulos entre [-pi/2 ; pi/2]    
--               Obs.(2): SIDEBAND serve para passar um sinal de SIDEBAND_WIDTH bits
--                        por todo o pipeline do CORDIC, o sinal não influencia no design
--                        e pode ser usado para sincronizar sinais.                      
---------------------------------------------------------------------------------------------


---------------
-- Libraries --
---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;    
use ieee_proposed.fixed_pkg.all;          

------------
-- Entity --
------------

entity cordic_core is
    generic (
        SIDEBAND_WIDTH                      : integer; -- Define tamanho do sinal sideband_data, se 0, o sinal não é sintetizado.
        CORDIC_INTEGER_PART                 : integer; -- sfixed integer part;    ex: sfixed(0 downto -19) --> 0.1111111111111111111 ~ +1.000 
        CORDIC_FRAC_PART                    : integer; -- sfixed fractional part; ex: sfixed(0 downto -19) --> 1.1010000000000000000 = -0.750
        N_CORDIC_ITERATIONS                 : natural  -- número de iterações do CORDIC (número de cordic_slices instanciados)
    );
    port(
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset
        
        sideband_data_i                     : in  std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
        sideband_data_o                     : out std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
        
        valid_i                             : in  std_logic; -- Indica que os sinais de dados (X_i,Y_i,Z_i) são válidos no ciclo atual       
        X_i                                 : in  sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART); -- Componente x do vetor de entrada
        Y_i                                 : in  sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART); -- Componente y do vetor de entrada
        Z_i                                 : in  sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART); -- Componente z do vetor de entrada (o ângulo)
        
        valid_o                             : out std_logic; -- Indica que os sinais de dados (X_o,Y_o,Z_o) são válidos no ciclo atual       
        X_o                                 : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART); -- Componente x do vetor de entrada
        Y_o                                 : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART); -- Componente y do vetor de entrada
        Z_o                                 : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART)  -- Componente z do vetor de entrada (o ângulo)
    );
end cordic_core;

------------------
-- Architecture --
------------------
architecture behavioral of cordic_core is
    
    ---------------
    -- Component --
    ---------------
    component cordic_slice
        generic(
            SIDEBAND_WIDTH                  : integer;
            CORDIC_INTEGER_PART             : integer; -- sfixed integer part 
            CORDIC_FRAC_PART                : integer; -- sfixed fractional part
            N_CORDIC_ITERATIONS             : natural  -- number of cordic iterations
        );
        port(
            -- Clock interface
            clock_i                         : in  std_logic;
            areset_i                        : in  std_logic; -- Positive async reset
            
            -- Control interface
            enable_i                        : in  std_logic; -- Hold signal
            valid_i                         : in  std_logic; -- Data valid in
            valid_o                         : out std_logic; -- Data valid out

            sideband_data_i                 : in  std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
            sideband_data_o                 : out std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
            
            -- Rotational angle values
            shift_value_i                   : in  integer range 0 to N_CORDIC_ITERATIONS; -- Tamanho do shift a ser feito 
            current_rotation_angle          : in  sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART); -- Ângulo sendo aplicado (-2^k)
            
            --Input vector(X_i,Y_i) + angle(Z_i)
            X_i                             : in  sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
            Y_i                             : in  sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
            Z_i                             : in  sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

            -- Ouput vector(X_o,Y_o) + angle(Z_o)
            X_o                             : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
            Y_o                             : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
            Z_o                             : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART)
        );
    end component;
  
    -----------
    -- Types --
    -----------
    type sfixed_connecting_array is array (0 to N_CORDIC_ITERATIONS) of sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    type rotation_angles_type is array (0 to N_CORDIC_ITERATIONS-1) of sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    type sideband_vector_type is array (0 to N_CORDIC_ITERATIONS) of std_logic_vector((SIDEBAND_WIDTH - 1) downto 0); 
    
    ---------------
    -- Functions --
    ---------------

    function GenerateRotationAngles(N_ITERATIONS : natural)
                                    return rotation_angles_type is
        variable RotationVector : rotation_angles_type;
    begin
        for I in 0 to N_ITERATIONS-1 loop
            -- Ângulos pré-calculados de rotação usados pelo cordic_slice ( arctg(2^(-I)), I -> Cordic stage index)
            RotationVector(I) := to_sfixed(arctan(2.0 ** real(-I)), CORDIC_INTEGER_PART, CORDIC_FRAC_PART); 
        end loop;
        return RotationVector;
    end function;
    
    ---------------
    -- Constants --
    ---------------
    constant all_rotation_angles            : rotation_angles_type := GenerateRotationAngles(N_CORDIC_ITERATIONS);
    
    -------------
    -- Signals --
    -------------

    -- Cordic-slices vectors
    signal X_vector                         : sfixed_connecting_array; -- X coordenada
    signal Y_vector                         : sfixed_connecting_array; -- Y coordenada
    signal Z_vector                         : sfixed_connecting_array; -- Z coordenada (ângulo)
    signal valid_vector                     : std_logic_vector(0 to N_CORDIC_ITERATIONS) := (others => '0'); 

    -- Sideband vector
    signal sideband_data_vector             : sideband_vector_type;
    
begin
    -----------
    -- Input --
    -----------
    X_vector(0)             <= X_i; 
    Y_vector(0)             <= Y_i;
    Z_vector(0)             <= Z_i;
    valid_vector(0)         <= valid_i;
    sideband_data_vector(0) <= sideband_data_i;

    -----------------------------
    -- Cordic slices instances --
    -----------------------------

    cordic_array : for cordic_index in 0 to (N_CORDIC_ITERATIONS - 1) generate
        cordic_element : cordic_slice
            generic map(
                SIDEBAND_WIDTH         => SIDEBAND_WIDTH,
                CORDIC_INTEGER_PART    => CORDIC_INTEGER_PART,
                CORDIC_FRAC_PART       => CORDIC_FRAC_PART,
                N_CORDIC_ITERATIONS    => N_CORDIC_ITERATIONS
            )
            port map(
                -- Clock interface
                clock_i                => clock_i,
                areset_i               => areset_i,

                -- Control interface
                enable_i               => '1', -- Enable não está sendo considerado no design, '1' fará o sinal não ser sintetizado
                valid_i                => valid_vector(cordic_index),
                valid_o                => valid_vector(cordic_index+1),

                sideband_data_i        => sideband_data_vector(cordic_index),
                sideband_data_o        => sideband_data_vector(cordic_index + 1),

                -- Rotational angle values
                shift_value_i          => cordic_index,
                current_rotation_angle => all_rotation_angles(cordic_index),
                
                --Input vector + angle
                X_i                    => X_vector(cordic_index),
                Y_i                    => Y_vector(cordic_index),
                Z_i                    => Z_vector(cordic_index),
                
                --Output vector + angle                
                X_o                    => X_vector(cordic_index+1),
                Y_o                    => Y_vector(cordic_index+1),
                Z_o                    => Z_vector(cordic_index+1)
            );    
    end generate;

    ------------
    -- Output --
    ------------
    X_o                 <= X_vector(N_CORDIC_ITERATIONS);
    Y_o                 <= Y_vector(N_CORDIC_ITERATIONS);
    Z_o                 <= Z_vector(N_CORDIC_ITERATIONS);
    valid_o              <= valid_vector(N_CORDIC_ITERATIONS);
    sideband_data_o     <= sideband_data_vector(N_CORDIC_ITERATIONS);
     
end behavioral;
