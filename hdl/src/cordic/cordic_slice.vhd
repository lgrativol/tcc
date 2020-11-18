---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Agosto/2020                                                                
-- Module Name: cordic_slice                                                                
-- Author Name: Versão original Felipe Calliari, update: Lucas Grativol Ribeiro            
--                                                                                         
-- Revision Date: 18/11/2020                                                               
-- Tool version: Vivado 2017.4                                                             
--                                                                                         
-- Goal: Implementar uma iteração algoritmo CORDIC versão rotacional
--       * x_(k+1) = Ak.(x_k - d_k 2^(-k)y_k)
--       * y_(k+1) = Ak.(y_k + d_k 2^(-k)x_k)
--       * z_(k+1) = z_k - d_k.arctg(2^(-k))
--          
-- Description: 1 slice implementa 1 iteração do algoritmo descrito acima note que :
--              
--        (1)   (x_k,y_k,z_k) = (X_i,Y_i,Z_i), onde Z_i é o ângulo para rotacionar
--        (2)   O objetivo do algoritmo é levar Z_i para 0 (zero), então cada ciclo de 
--              clock, determina os d_k, como -1 ou +1, com o objetivo de aproximar
--              Z_i de zero.
--        (3)   Os termos 2^(-k) são transformados em shifts aritméticos para direita
--        (4)  A quantidade de shifts a serem feitas são passadas pelo cordic_core
--        (5)   O termo arctg(2^(-k)) são pré-calculados pelo cordic_core
--
--        Obs.(1): SIDEBAND serve para passar um sinal de SIDEBAND_WIDTH bits (sideband_data)
--                 por todo o pipeline da entidade, o sinal não influencia no design
--                 e pode ser usado para sincronizar sinais.  
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

entity cordic_slice is
    generic(
        SIDEBAND_WIDTH                  : integer; -- Define tamanho do sinal sideband_data, se 0, o sinal não é sintetizado.
        CORDIC_INTEGER_PART             : integer; -- sfixed integer part;    ex: sfixed(0 downto -19) --> 0.1111111111111111111 ~ +1.000 
        CORDIC_FRAC_PART                : integer; -- sfixed fractional part; ex: sfixed(0 downto -19) --> 1.1010000000000000000 = -0.750
        N_CORDIC_ITERATIONS             : natural  -- número de iterações do CORDIC
    );
    port(
        -- Clock interface
        clock_i                         : in  std_logic;
        areset_i                        : in  std_logic; -- Positive async reset
        
        -- Control interface
        enable_i                        : in  std_logic; -- Hold signal
        valid_i                         : in  std_logic; -- Indica que os sinais de dados (X_i,Y_i,Z_i) são válidos no ciclo atual       
        valid_o                         : out std_logic; -- Indica que os sinais de dados (X_o,Y_o,Z_o) são válidos no ciclo atual       

        sideband_data_i                 : in  std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
        sideband_data_o                 : out std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
        
        -- Rotational angle values
        shift_value_i                   : in  integer range 0 to N_CORDIC_ITERATIONS; -- TODO: move to generic
        current_rotation_angle          : in  sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART); --TODO: move to internal memory (ROM/LUT)
        
        --Input vector + angle
        X_i                             : in  sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        Y_i                             : in  sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        Z_i                             : in  sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

        -- Ouput vector + angle
        X_o                             : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        Y_o                             : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        Z_o                             : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART)
    );
end cordic_slice;

------------------
-- Architecture --
------------------

architecture Behavioral of cordic_slice is

    -------------
    -- Signals --
    -------------
    signal X                                : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART); 
    signal Y                                : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal Z                                : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART); 
    signal valid_r                          : std_logic;

    signal sideband_data_reg                : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
        
begin

    ------------------------------------------------------------------
    --                     Algoritmo CORDIC                           
    --                                                                
    --   Goal: Rotacionar o ângulo Z_i para próximo de zero            
    --         somando ou subtraindo current_rotation_angle
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: valid_i;
    --          enable_i;
    --          Z_i;
    --          shift_value_i;
    --          current_rotation_angle;
    --          (X_i,Y_i)
    --
    --   Output: (X,Y,Z)
    --
    --   Result: Ângulo Z se aproxima de zero e (X,Y) são rotacionados 
    --           de current_rotation_angle.   
    ------------------------------------------------------------------
    cordic_register : process(clock_i, areset_i)
    begin
        if (areset_i = '1') then
            valid_r <= '0';
        elsif (rising_edge(clock_i)) then
            valid_r  <=  valid_i;

            if (valid_i = '1' and enable_i = '1') then 
                -- Testando sinal do ângulo Z
                if (Z_i > 0) then -- Z>0, precisa rotacionar sentido horário  (Z - current_rotation_angle)
                    X <= resize(X_i - (Y_i sra shift_value_i), CORDIC_INTEGER_PART, CORDIC_FRAC_PART);
                    Y <= resize(Y_i + (X_i sra shift_value_i), CORDIC_INTEGER_PART, CORDIC_FRAC_PART);
                    Z <= resize(Z_i - current_rotation_angle,  CORDIC_INTEGER_PART, CORDIC_FRAC_PART);
                else -- Z<0, precisa rotacionar sentido anti-horário  (Z + current_rotation_angle)
                    X <= resize(X_i + (Y_i sra shift_value_i), CORDIC_INTEGER_PART, CORDIC_FRAC_PART);
                    Y <= resize(Y_i - (X_i sra shift_value_i), CORDIC_INTEGER_PART, CORDIC_FRAC_PART);
                    Z <= resize(Z_i + current_rotation_angle,  CORDIC_INTEGER_PART, CORDIC_FRAC_PART);
                end if;
            end if;
        end if;        
    end process;

    ------------------------------------------------------------------
    --                    Sinal Sideband                            
    --                                                                
    --   Goal: Aplicar sobre o sinal sideband o mesmo delay que os sinais de
    --         de entrada sofrem. 
    --
    --   Clock & reset domain: clock_i & sem reset
    --
    --
    --   Input: valid_i;
    --          enable_i;
    --          Z_i;
    --          sideband_data_i
    --
    --   Output: sideband_data_reg
    --
    --   Result: O sinal é atrasado igual as entradas, podendo ser usado
    --           para sincroninzar qualquer sinal com o pipeline do CORDIC
    --           sem precisar de lógica externa.  
    ------------------------------------------------------------------
    sideband_proc : process(clock_i)
    begin
        if ( rising_edge(clock_i) )then
            if (valid_i = '1' and enable_i = '1') then 
                sideband_data_reg <= sideband_data_i;
            end if;
        end if;
    end process;
    
    ------------
    -- Output --
    ------------
    X_o <= X;
    Y_o <= Y;
    Z_o <= Z;
    valid_o <= valid_r;
    sideband_data_o <= sideband_data_reg;
    
end Behavioral;
