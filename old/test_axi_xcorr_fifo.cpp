#include <iostream>
#include <sstream>
#include <string>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <unistd.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <stdint.h>
#include <math.h>
#include <assert.h>

#define _ONLY_INTERFACE_SIZE_
#include "xcorr.h"

using namespace std;

#define DINT_T_MULT 128
#define DINT_T_MASK 255

//#define GEN_TCL_TESTBENCH

template <class T>
int getNextLineAndSplitIntoTokens(std::istream& str, T vec[])
{
    std::string                line;
    std::getline(str,line);

    std::stringstream          lineStream(line);
    std::string                cell;

    int n = 0;
    while(std::getline(lineStream,cell, ','))
    {
    	vec[n] = atof(cell.c_str());
    	//vec[n] = T(cell.c_str());
        n++;
    }
    return n;
}

template <class T>
int getDatLineAndSplitIntoTokens(std::istream& str, T vec[])
{
	int numElements;
	str.read((char*)&numElements, sizeof(numElements));
	if( !str.good() )
		return 0;

	for(int n = 0; n < numElements; n++) {
		float tmp;
		str.read((char*)&tmp, sizeof(tmp));
		vec[n] = tmp;
	}

    return numElements;
}

#define MAX_REL_DIF 0.05
#define MAX_ABS_DIF 0.0001

#define MAX_REL_DIF_SINGLE 0.15
#define MAX_REL_DIF_FINAL  0.10
#define MAX_ERRORS_TOTAL   0.10 // 10% de erros


int compareOuts(float *out, float *outRef,
		int outSize, int runs, float maxRelDif)
{
	int errors = 0;

	float avgAbs = 0;
	for(int i = 1; i < outSize; i++ ) {
		avgAbs += fabs((float)outRef[i]);
	}
	avgAbs /= (outSize-1);

	/*
	for(int i = 1; i < outSize; i++ ) {
		float difAbs = fabs((float)outRef[i]-(float)out[i]);
		float maxAbs = fabs(std::max((float)outRef[i],(float)out[i]));
		float minAbs = fabs(std::min((float)outRef[i],(float)out[i]));

		if( (minAbs && difAbs/maxAbs > MAX_REL_DIF) ||
		    (!minAbs && difAbs > MAX_ABS_DIF ) ) {
			cout << "run " << runs << "/" << i << " : " <<
					outRef[i] << " " << out[i] << "\n";
			cout << "dif/max: " << difAbs << "/" << maxAbs <<
					" = " << difAbs/maxAbs << "\n";
			errors++;
		}
	}
	*/

	for(int i = 1; i < outSize; i++ ) {
		float difAbs = fabs((float)outRef[i]-(float)out[i]);
		float maxAbs = fabs(std::max((float)outRef[i],(float)out[i]));

		if( difAbs/avgAbs > maxRelDif &&
			difAbs/maxAbs > maxRelDif ) {
			cout << "run " << runs << "/" << i << " : " <<
					outRef[i] << " " << out[i] << "\n";
			cout << "dif/avg: " << difAbs/avgAbs << " dif/val: " << difAbs/maxAbs <<"\n";
			errors++;
		}
	}


	return errors;
}

uint32_t floatToDin(float x) {
	return ((uint32_t)((int)floor(x * DINT_T_MULT))) & DINT_T_MASK;
}

int fifoWritten = 0;

void *ptr_SLCR;
#define BASE_SLCR           0xF8000000
#define SLCR_UNLOCK         0x0008
#define SLCR_UNLOCK_VAL     0xDF0D
#define SLCR_LOCK           0x0004
#define SLCR_LOCK_VAL       0x767B
#define SLCR_FPGA0_THR_CNT  0x0178
#define SLCR_FPGA_RST_CTRL  0x0240

void *ptr_STREAM_FIFO;
#define BASE_STREAM_FIFO    0x43c00000
#define STREAM_FIFO_ISR     0x0000
#define STREAM_FIFO_IER     0x0004
#define STREAM_FIFO_TDFR    0x0008
#define STREAM_FIFO_TDFV    0x000c
#define STREAM_FIFO_TDFD    0x0010
#define STREAM_FIFO_TLR     0x0014
#define STREAM_FIFO_RDFR    0x0018
#define STREAM_FIFO_RDFO    0x001c
#define STREAM_FIFO_RDFD    0x0020
#define STREAM_FIFO_RLR     0x0024
#define STREAM_FIFO_SSR     0x0028
#define STREAM_FIFO_TDR     0x002C
#define STREAM_FIFO_RDR     0x0030


#define MAP_PAGE_SIZE       4096

uint32_t read_SLCR (int offset)        { return *((volatile uint32_t *)((uint32_t)ptr_SLCR+offset)); }
void     write_SLCR(int offset, uint32_t val) { *((volatile uint32_t *)((uint32_t)ptr_SLCR+offset)) = val; }
uint32_t read_SF   (int offset)        { return *((volatile uint32_t *)((uint32_t)ptr_STREAM_FIFO+offset)); }
void     write_SF  (int offset, uint32_t val) { *((volatile uint32_t *)((uint32_t)ptr_STREAM_FIFO+offset)) = val; }

void init_axi_fifo()
{
        int fd;
    
        fd=open("/dev/mem",O_RDWR);
        if(fd<1) {
                perror("open /dev/mem");
                exit(-1);
        }
        
        ptr_SLCR=mmap(NULL,MAP_PAGE_SIZE,PROT_READ|PROT_WRITE,MAP_SHARED,fd,BASE_SLCR);
        if((int)ptr_SLCR==-1) {
                perror("mapping BASE_SLCR");
                exit(-1);
        }
        ptr_STREAM_FIFO=mmap(NULL,MAP_PAGE_SIZE,PROT_READ|PROT_WRITE,MAP_SHARED,fd,BASE_STREAM_FIFO);
        if((int)ptr_SLCR==-1) {
                perror("mapping BASE_STREAM_FIFO");
                exit(-1);
        }

        /* enable fclk_clk0 */
        write_SLCR(SLCR_FPGA0_THR_CNT, 0);
        
        /* fpga_reset0 */
        write_SLCR(SLCR_UNLOCK, SLCR_UNLOCK_VAL);
        write_SLCR(SLCR_FPGA_RST_CTRL, 1);
        write_SLCR(SLCR_FPGA_RST_CTRL, 0);
        write_SLCR(SLCR_LOCK, SLCR_LOCK_VAL);
}

void resetStreamFifo()
{
        /* reset stream fifo */
        write_SF(STREAM_FIFO_SSR, 0xa5);
        write_SF(STREAM_FIFO_ISR, 0xffffffff);
        read_SF(STREAM_FIFO_ISR);
        read_SF(STREAM_FIFO_IER);
        write_SF(STREAM_FIFO_IER, 0x0C000000);
        write_SF(STREAM_FIFO_TDR, 0x02);
        read_SF(STREAM_FIFO_RDFO);
        read_SF(STREAM_FIFO_TDFV);
        fifoWritten = 0;
}


int inputWrite(uint32_t v)
{
        write_SF(STREAM_FIFO_TDFD,v);
        return ++fifoWritten;
}

void inputTransmit()
{
	//printf("transmiting %d...\n", fifoWritten * 4);
        write_SF(STREAM_FIFO_TLR,fifoWritten * 4);
	fifoWritten = 0;
        read_SF(STREAM_FIFO_TDFV);
}

uint32_t outputRead()
{
        return read_SF(STREAM_FIFO_RDFD);
}

int outputReadSize()
{
        return read_SF(STREAM_FIFO_RDFO);
}

#define RETRY_POLL_TIMES 10000

int waitOutputSize(int outSize)
{
	for(int i = 0; i < RETRY_POLL_TIMES; i++) {
		if( outputReadSize() == outSize ) {
			return 1;
		}
	}
	printf("waitOutputSize(%d) failed (%d)\n", outSize, outputReadSize());
	return 0;
}

int waitTransmitComplete()
{
	uint32_t TC_FLAG = (1<<27);
	for(int i = 0; i < RETRY_POLL_TIMES ; i++) {
		if( read_SF(STREAM_FIFO_ISR) & TC_FLAG ) {
			write_SF(STREAM_FIFO_ISR, TC_FLAG); // clear TC
			return 1;
		}	
	}
	printf("waitTransmitComplete() failed\n");
	return 0;
}

int waitTxVacancy(int words)
{
	for(int i = 0; i < RETRY_POLL_TIMES; i++) {
		if( read_SF(STREAM_FIFO_TDFV) >= words ) {
			return 1;
		}
	}
	printf("waitTxVacancy(%d) failed (%d)\n", words, read_SF(STREAM_FIFO_TDFV));
	return 0;
}


#include <fstream>

int main(int argc, char *argv[])
{
	int res = 0;

	float a[MAX_XCORR_A_SIZE];
	uint32_t aVec[MAX_XCORR_A_SIZE];
	float v[MAX_XCORR_V_SIZE];
	uint32_t vVec[MAX_XCORR_A_SIZE];
	float out[MAX_XCORR_OUT_SIZE];
	uint32_t out32[MAX_XCORR_OUT_SIZE];
	float outRef[MAX_XCORR_OUT_SIZE];
	float sumRef[MAX_XCORR_OUT_SIZE];
	int aSize, vSize, outSize, sumSize;
	int runs = 0;
	int tests = 0;
	int errors = 0;
	bool testFinalOnly = false;
	bool testSingle = false;
	bool ignoreErrors = true;
	bool readTimeOnly = false;
	bool muteMessages = false;
	
	cout << argv[0] << " opcoes: 'f'-finalOnly, 's'-single, 'r'-readTimeOnly, 'm'-muteMessages\n";
	
	if(argc > 1) {
		if(strchr(argv[1],'f')) testFinalOnly = true;
		if(strchr(argv[1],'s')) testSingle = true;
		if(strchr(argv[1],'r')) readTimeOnly = true;
		if(strchr(argv[1],'m')) muteMessages = true;
	}
	
	string fileSumName("xcorr-emat-sum.txt");
	string fileDatName("xcorr-emat.dat");

        cout << "Inicializando AXI + fclk_clk0\n";
        init_axi_fifo();
        cout << "Inicializando AXI Stream FIFO (se travar agora o bitfile deve estar errado)\n";
        resetStreamFifo();

	cout << "Abrindo arquivo com dados de referencia\n";

	ifstream fileSum ( fileSumName.c_str() );
	if(!fileSum.good()) {
		cerr << "Erro abrindo " << fileSumName << std::endl;
		return -2;
	}
	sumSize = getNextLineAndSplitIntoTokens<float>(fileSum, &sumRef[1]);
	cout << "Soma final (ascansize): " << sumSize << "\n";

	if(!ifstream(fileDatName.c_str()).good()) {
		cout << "Tentando descompactar " << fileDatName << std::endl;
		string cmd("gunzip ");
		cmd += fileDatName + ".gz";
		system(cmd.c_str());

		if(!ifstream(fileDatName.c_str()).good()) {
			cerr << "Erro abrindo " << fileDatName << std::endl;
			return -2;
		}
	}

	ifstream file ( fileDatName.c_str(), std::ios::binary );
	while(file.good())
	{
		vSize = getDatLineAndSplitIntoTokens<float>(file, v);
		aSize = getDatLineAndSplitIntoTokens<float>(file, a);
		outSize = getDatLineAndSplitIntoTokens<float>(file, &outRef[1]);

		if(vSize && aSize && outSize) {
			for( int i=0, j=0; i < aSize; i+=4, j++ ) {
				aVec[j] =    		 (floatToDin(a[i+0]) << 0) +
							 (floatToDin(a[i+1]) << 8) +
							 (floatToDin(a[i+2]) << 16) +
							 (floatToDin(a[i+3]) << 24);
			}
			for( int i=0, j=0; i < vSize; i+=4, j++ ) {
				vVec[j] =  		 (floatToDin(v[i+0]) << 0) +
							 (floatToDin(v[i+1]) << 8) +
							 (floatToDin(v[i+2]) << 16) +
							 (floatToDin(v[i+3]) << 24);
			}
		}

		if(vSize && aSize && outSize && !readTimeOnly) {
			if(!muteMessages) {
				cout << "axi_xcorr run: " << runs << "\n";
			}

                        //resetStreamFifo();

			if( !testFinalOnly ) {
				/* se quiser pegar os resultados intermediarios escreve o tamanho
				 * e depois precisa escrever zero depois para forcar a saida. */
				inputWrite(outSize);
			} else {
				if( !runs ) {
					/* se for testar apenas a saida final, usa o sumSize */
					inputWrite(sumSize);
				}
			}

			//waitTxVacancy(aSize/4+1 + vSize/4+1 + 1);
			
			inputWrite(aSize);
			for( int i=0, j=0; i < aSize; i+=4, j++ ) {
				inputWrite(aVec[j]);
			}
			inputWrite(vSize);
			for( int i=0, j=0; i < vSize; i+=4, j++ ) {
				inputWrite(vVec[j]);
			}
			
			if( !testFinalOnly ) {
				inputWrite(0); // fim
			}
			
                        inputTransmit();
			waitTransmitComplete();

			//axi_xcorr(input,output);
			
			
			if( !testFinalOnly ) {
				waitOutputSize(outSize);
	
				assert( outputReadSize() == outSize );
				for(int i = 0; i < outSize; i++) {
					out32[i] = outputRead();
					out[i] = ((int32_t)out32[i]) / (float)(1<<(DOUT_BITS_INT+DOUT_BITS_FRAC-32));
				}
				/*
				for(int j=0; j < outSize;j++) {
					printf("assert {[xcorr_rdfd] eq %u}\n", out32[j]);
				}
				*/
	
				errors += compareOuts(out, outRef, outSize, runs, MAX_REL_DIF_SINGLE);
				tests += outSize;
			}
			runs++;
		}

		if( (errors && !ignoreErrors) || testSingle ) {
			break;
		}

	}

	if( testFinalOnly && !readTimeOnly ) {
		inputWrite(0); // fim
		inputTransmit();
		waitTransmitComplete();
		waitOutputSize(sumSize);
		assert( outputReadSize() == sumSize );
		for(int i = 0; i < sumSize; i++) {
			out32[i] = outputRead();
			out[i] = ((int32_t)out32[i]) / (float)(1<<(DOUT_BITS_INT+DOUT_BITS_FRAC-32));
		}
		
		errors += compareOuts(out, sumRef, sumSize, -1, MAX_REL_DIF_FINAL);
		tests += sumSize;

		cout << "Soma final (copiar em ascans_apfixed.csv):" << "\n";
		cout << DIN_BITS_INT << "," <<
				DIN_BITS_FRAC << "," <<
				DOUT_BITS_INT << "," <<
				DOUT_BITS_FRAC << ",";
		for(int i = 0; i < sumSize; i++) {
			cout << out[i];
			if( i != sumSize -1 ) {
				cout << ",";
			}
		}
		cout << "\n";
	}

	cout << "Resumo: " << runs << " correlacoes, " << tests <<
			" valores testados e " << errors << " erros.\n";

	if ( ((float)errors) / tests > MAX_ERRORS_TOTAL ) {
		res = -1;
	}

	return res;
}
