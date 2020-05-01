library ieee;
use ieee.std_logic_1164.all;

-- Prova Finale di Reti Logiche, AA 2019/2020
-- Componenti:
-- Stefano Dalla Longa,	codice persona 10535602
-- Nicolò Brandolese,	codice persona 10531144
-- modello fpga usato: xc7a200tfbg484-1

--entity declaration

entity project_reti_logiche is
	port(
		--input signals
		i_clk		: in std_logic;						--segnale di CLOCK generato dal tb
		i_start		: in std_logic;						--segnale di START generato dal tb
		i_rst		: in std_logic;						--segnale di RESET che inizializza la macchina pronta per ricevere il primo segnale di START
		i_data		: in std_logic_vector(7 downto 0);	--vettore proveniente dalla memoria in seguito a una richiesta di lettura
		--output signals
		o_address	:out std_logic_vector(15 downto 0);	--vettore di uscita contenente l'indirizzo dell'area di memoria desiderata
		o_done		:out std_logic;						--segnale di FINE ELABORAZIONE che comunica la fine dell'elaborazione e la scrittura del risultato in memoria
		o_en		:out std_logic;						--segnale di ENABLE da dover inviare alla memoria per poter comunicare (sia in lettura che in scrittura)
		o_we		:out std_logic;						--segnale di WRITE ENABLE da inviare alla memoria. Se ='1', richiede la scrittura, se = '0' richiede la lettura
		o_data		:out std_logic_vector(7 downto 0)	--vettore di uscita dal componente verso la memoria
	);
end project_reti_logiche;


--architecture declaration

architecture rtl of project_reti_logiche is
	--internal signals
	--(still blank for now)

begin
	--architectural behaviour
	--(still blank for now)
end rtl;