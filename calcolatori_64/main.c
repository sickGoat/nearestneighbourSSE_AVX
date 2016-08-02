/* CdL Magistrale in Ingegneria Informatica
 * Corso di Calcolatori Elettronici 2 - a.a. 2014/15
 *
 * Progetto di un algoritmo di Nearest Neighbor Condensation
 * in linguaggio assembly x86-64 + AVX
 *
 * Fabrizio Angiulli, 18 aprile 2014
 *
 ****************************************************************************/

/*

 Software necessario per l'esecuzione:

     NASM (www.nasm.us)
     GCC (gcc.gnu.org)

 entrambi sono disponibili come pacchetti software
 installabili mediante il packaging tool del sistema
 operativo; per esempio, su Ubuntu, mediante i comandi:

     sudo apt-get install nasm
     sudo apt-get install gcc

 potrebbe essere necessario installare le seguenti librerie:

     sudo apt-get install lib32gcc-4.8-dev (o altra versione)
     sudo apt-get install libc6-dev-i386

 Per generare il file eseguibile:

 nasm -f elf64 fcnn64.nasm && gcc -O0 -m64 -mavx fcnn64.o fcnn64c.c -o fcnn64c && ./fcnn64c

 oppure

 ./runfcnn32

*/

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <time.h>
#include <xmmintrin.h>

/*
 *
 *	Le funzioni sono state scritte assumento che le matrici siano memorizzate
 * 	mediante un array (float*), in modo da occupare un unico blocco
 * 	di memoria, ma a scelta del candidato possono essere
 * 	memorizzate mediante array di array (float**).
 *
 * 	In entrambi i casi il candidato dovrà inoltre scegliere se memorizzare le
 * 	matrici per righe (row-major order) o per colonne (column major-order).
 *
 * 	L'assunzione corrente è che le matrici siano in row-major order.
 *
 */


#define	MATRIX		float*
#define	VECTOR		float*

#define	DATASET		float*
#define SUBSETID	int*

extern void dist(float*a,float*b,int dim,float*result);

extern void centroide(float *dataset,int row_dataset,int column_dataset,float class,float *centro,int* result);
extern int nearestVoren(float *dataset,int row_dataset,int column_dataset,int target_index,int *subset,int dim_subset);
extern void nn(float*dataset,int column_dataset,int target_index,int*subset,int dim_subset,int *res);
extern void nnC(float* dataset,int row_dataset,int column_dataset,float* centro,float class,int *result);
void* get_block(int size, int elements) {
	return _mm_malloc(elements*size,32);
}


void free_block(void* p) {
	_mm_free(p);
}


MATRIX alloc_matrix(int rows, int cols) {
	return (MATRIX) get_block(sizeof(float),rows*cols);
}


void dealloc_matrix(MATRIX mat) {
	free_block(mat);
}


/*
 *
 * 	load_input
 * 	===========
 *
 *	Legge da file il training set codificato come una matrice di n righe
 * 	e (d+1) colonne, con l'etichetta nell'ultima colonna, e lo memorizza
 * 	in un array lineare in row-major order
 *
 * 	Codifica del file:
 * 	primi 4 byte: numero di colonne (d+1) --> numero intero in complemento a due
 * 	4 byte successivi: numero di righe (n) --> numero intero in complemento a due
 * 	n*(d+1)*4 byte successivi: training set T in row-major order --> numeri floating-point a precisione singola
 *
 */
DATASET load_input(char* filename, int *n, int *d, int *m) {
	FILE* fp;
	int rows, cols, status, i,j ,cols_padding;

	fp = fopen(filename, "rb");

	//if (fp == NULL) {
	//	printf("Bad dataset file name!\n");
	//	exit(0);
	//}

	status = fread(&cols, sizeof(int), 1, fp);
	status = fread(&rows, sizeof(int), 1, fp);
	DATASET T = alloc_matrix(rows,cols);
	status = fread(T, sizeof(float), rows*cols, fp);
	fclose(fp);

	*m = 0;
	for (i = 0; i < rows; i++)
		if (T[i*cols+cols-1] > *m)
			*m = T[i*cols+cols-1];

	/*gestione padding */
	if( cols%8 != 0 ){
		cols_padding = cols + 8 - cols%8;
	}

	DATASET T_padding = alloc_matrix(rows,cols_padding);

	for( i = 0 ; i < rows  ; i++ ){
		for(j = 0 ; j < cols-1  ; j++ ){
			T_padding[i*cols_padding+j] = T[i*cols+j];
		}
		for( j = cols-1 ; j < cols_padding-1 ; j++ ){
			T_padding[i*cols_padding+j] = 0;
		}
		T_padding[i*cols_padding+cols_padding-1] = T[i*cols+cols-1];
	}

	dealloc_matrix(T);
	(*m)++;
	*n = rows;
	*d = cols_padding;

	return T_padding;
}


void save_output(SUBSETID Sid, int Sn) {
	FILE* fp;
	int i;

	fp = fopen("subset.txt", "w");
	for (i = 0; i < Sn; i++)
		fprintf(fp, "%d\n", Sid[i]);
	fclose(fp);
}



// extern void fcnn32(DATASET t, int n, int d, int m, SUBSETID Sid, int* Sn);

/*
 *	fcnn
 * 	====
 *
 *	T contiene il training set codificato come una matrice di n righe
 * 	e (d+1) colonne, con l'etichetta nell'ultima colonna, memorizzata
 * 	in un array lineare in row-major order
 *
 *	Se lo si ritiene opportuno, è possibile cambiare la codifica in memoria
 * 	del training set.
 *
 * 	Restituisce in Sid gli identificatori degli esempi di T che appartengono
 * 	al sottoinsieme S ed in Sn il numero di oggetti in S.
 * 	Si assume che gli identificatori partono da 0.
 *
 */
SUBSETID fcnn(DATASET T, int n, int d, int m, int* Sn) {
	SUBSETID Sid = calloc(sizeof(int),n);

    // -------------------------------------------------
    // Codificare qui l'algoritmo risolutivo
    // -------------------------------------------------

    // fcnn64(T, n, d, m, Sid, Sn); // Esempio di chiamata di funzione assembly

    // -------------------------------------------------

    return Sid;
}

/*
  Prende in input due indici di riga e ne restituisce
  la distanza ( x e y puntano direttamente alla prima
  posizione della riga)
*/
/*
void dist(float* x, float* y,int column_dataset,float *result){
    int i;
    float distance = 0.0,sq_distance = 0.0;
    for( i = 0 ; i < column_dataset-1 ; i++ ){
        distance += (float)pow(x[i]-y[i],2);
    }
    *result = (float)sqrt(distance);

}*/
/*
  Prende in input un nuovo vettore e una riga del dataset
  e ne restituisce la distanza
*/
float distRN(DATASET dataset,int column_dataset,VECTOR target,int row){
    int i;
    float distance=0;
    for( i = 0 ; i < column_dataset-1 ; i++ ){
      distance += (float)pow((dataset[row+i]-target[i]),2);
    }

  return (float)sqrt(distance);
}

/*
  Implementazione del metodo nn(q,S) : in cui S rappresenta una partizione
  della dataset rappresentata come un array di indici e q rappresenta una riga
  della matrice
	target : indice di una riga del dataset (q)
	return : un indice del subset che contiene la riga del dataset
*/
/*
int nn(DATASET dataset,int column_dataset,int target,SUBSETID subset,int dim_subset){
    int i = 0 , min_index = 0;
    float cur_min = -1, cur_dist = 0;

    //caso subset vuota
    if( dim_subset == 0 )
      return -1;

    for( i = 0 ; i < dim_subset ; i++ ){
      //calcolo la distanza tra il target
      //e la riga della matrice puntata dal
      //contenuto di subset in posizione i
      dist(&dataset[target],&dataset[subset[i]*column_dataset],column_dataset,&cur_dist);
      if( cur_dist < cur_min || cur_min == -1 ){
        cur_min = cur_dist; min_index = i;
      }
    }

    return min_index;
}
*/
/*
  Funzione che mappa un vettore target sulla riga del dataset della medesima
  classe ad esso più vicina
*/
int nnClass(DATASET dataset, int row_dataset, int column_dataset,VECTOR target,float class){
  int i ,k, min_index = 0;
  float cur_min = -1, cur_dist = 0;

  for( i = 0 ; i < row_dataset ; i++ ){
    if( dataset[(i*column_dataset)+column_dataset-1] == class ){
      dist(target,&dataset[i*column_dataset],column_dataset,&cur_dist);
      if( cur_dist < cur_min || cur_min == -1 ){
        cur_min = cur_dist; min_index = i;
      }
    }
  }

  return min_index;
}

/*
  Funzione che effettua la divisione scalare con un array
*/
void divisioneScalare(VECTOR dividendo,float divisore,int column_dataset){
  int i=0;

  for( i = 0 ; i < column_dataset-1 ; i++ )
    dividendo[i] = dividendo[i]/divisore;
}

/*
    Prende in input il dataset, le sue dimensioni, l'id di una classe
    è un vettore in cui memoriazzare il centro ottenuto dalla media
    (vettore che dovrà essere inizializzato fuori dal metodo
    e poi sovrascritto)
*/
/*
int centroide(DATASET dataset,int row_dataset,int column_dataset,float class, VECTOR centro){
  int i,j,result;
  float stessa_classe = 0;

  for( i = 0 ; i < row_dataset ; i++ ){
    if( dataset[(i*column_dataset)+column_dataset-1] == class ){
      for( j = 0 ; j < column_dataset-1 ; j++ ){
        centro[j] += dataset[(i*column_dataset)+j];
      }
      stessa_classe++;
    }
  }

  divisioneScalare(centro,stessa_classe,column_dataset);
  //result = nnClass(dataset,row_dataset,column_dataset,centro,class);
  nnC(dataset,row_dataset,column_dataset,centro,class,&result);
  return result;
}
*/
/*
  Funzione che calcola i centroidi di ogni classe e ne scrive l'indice nell'array
  lista_centroidi che verrà sovrascritto a partire dalla prima posizione.
*/
void centroidi(DATASET dataset,int row_dataset, int column_dataset,int *lista_centroidi,int num_classi){
    int i,j;
    VECTOR centro;
    centro = (float*) _mm_malloc(column_dataset,32);
    memset(centro,0,sizeof(float)*column_dataset);
    for( i = 0 ; i < num_classi ; i++ ){
      centroide(dataset,row_dataset,column_dataset,(float)i,centro,&lista_centroidi[i]);
      //lista_centroidi[i] = centroide(dataset,row_dataset,column_dataset,(float)i,centro);

      memset(centro,0,sizeof(float)*column_dataset);
    }
}

/*
  Funzione che calcola gli elementi nella cella di voronoi dell'elemento puntato dal contenuto della subset
  all'indice target_index
	target_index : indice di un elemento della subset
*/
/*
void Vor(DATASET dataset,int row_dataset, int column_dataset,int target_index,SUBSETID subset,int dim_subset,int* voronoi_cell,int*dim_cell){
  int i,nearest;
  int *iteratore;

  iteratore = voronoi_cell;

  for( i = 0 ; i < row_dataset ; i++ ){
    nearest = nn(dataset,column_dataset,i*column_dataset,subset,dim_subset);
    if( target_index == nearest ){
      *iteratore = i;
      iteratore++;
      *dim_cell += 1;
    }
  }
}

int contains(int index_dataset,SUBSETID subset,int dim_subset){
	int i;

	for( i = dim_subset-1 ; i >= 0 ; i-- ){
		if( subset[i] == index_dataset )
			return 1;
	}

	return 0;
}
*/
/*
  Funzione che calcola i nemici nella cella dell'elemento puntato dal contenuto a target_index della subset
*/
/*
void Voren(DATASET dataset,int row_dataset,int column_dataset,int target_index,SUBSETID subset,int dim_subset,int*vor_enemies,int *num_enemies){
  int i,dim_cell = 0;
  int *iteratore,*vor_cell;

  iteratore = vor_enemies;
  vor_cell = (int*) calloc(sizeof(int),row_dataset);

  Vor(dataset,row_dataset,column_dataset,target_index,subset,dim_subset,vor_cell,&dim_cell);

  for( i = 0 ; i < dim_cell ; i++ ){
    if( dataset[vor_cell[i]*column_dataset+column_dataset-1] != dataset[subset[target_index]*column_dataset + column_dataset-1]
			&& !contains(vor_cell[i],subset,dim_subset)){
      *iteratore = vor_cell[i];
      iteratore++;
      *num_enemies += 1;
    }
  }
  free(vor_cell);
}
*/
/*
int NearestVoren(DATASET dataset,int row_dataset,int column_dataset,int target_index,SUBSETID subset,int dim_subset){
	int i,nearest;
	float cur_dist = 0,cur_min = -1,min_index = -1;

	for( i = 0 ; i < row_dataset ; i++ ){
		nearest = -1;
	    nn(dataset,column_dataset,i*column_dataset,subset,dim_subset,&nearest);
	    //nearest = nn(dataset,column_dataset,i*column_dataset,subset,dim_subset);

	    if( target_index == nearest
	    	&& dataset[subset[target_index]*column_dataset+column_dataset-1]!=dataset[i*column_dataset+column_dataset-1]){
	    	//Se la riga i è un nemico calcolo la distanza tra
	    	//l'array puntato dal target_index della subset e l'i-esima riga della matrice
	    	dist(&dataset[subset[target_index]*column_dataset],&dataset[i*column_dataset],column_dataset,&cur_dist);
	    	if( cur_dist < cur_min || cur_min == -1 ){
	    	   cur_min = cur_dist; min_index = i;
	    	}
	    }
	  }

	return min_index;
}
*/
SUBSETID fcnn32(DATASET dataset, int row_dataset, int column_dataset, int num_class, int* Sn){
  int i,dim_delta_s,nearest_enemy;
  int l=0;
  int *iteratore_subset,*iteratore_delta_s,*subset,*delta_s;
  printf("Inizio metodo");


  subset = (int*) _mm_malloc(sizeof(int)*row_dataset,16);
  iteratore_subset = subset;

  delta_s = (int*) _mm_malloc(sizeof(int)*row_dataset,16);
  iteratore_delta_s = delta_s;


  centroidi(dataset,row_dataset,column_dataset,delta_s,num_class);
  dim_delta_s = num_class;

  while( dim_delta_s != 0 ){
    for( i = 0 ; i < dim_delta_s ; i++ ){
    	*iteratore_subset = delta_s[i];
	  	iteratore_subset++;
	  	*Sn += 1;
    }

    dim_delta_s = 0;
    for( l = 0 ; l < *Sn ; l++ ){
    	nearest_enemy = -1;
    	nearest_enemy = nearestVoren(dataset,row_dataset,column_dataset,l,subset,*Sn);
    	//nearest_enemy = NearestVoren(dataset,row_dataset,column_dataset,i,subset,*Sn);

        if( nearest_enemy < row_dataset ){
          *iteratore_delta_s = nearest_enemy;
          iteratore_delta_s++;
          dim_delta_s++;
        }

    }

   iteratore_delta_s = delta_s;
  }

  _mm_free(delta_s);

  return subset;
}

int main(int argc, char** argv) {
	DATASET T;
	int n = 10;		// numero di esempi del training set
	int d = 2;		// numero di dimensioni di ogni esempio
	int m = 2;		// numero di classi
	int nearest = -1;

	char* filename = "/home/antonio/CEclipse/calcolatori/datasets/iris.dataset";
	int silent = 0, display = 0;
	int i, j;

	int par = 1;
	while (par < argc) {
		if (par == 1) {
			filename = argv[par];
			par++;
		} else if (strcmp(argv[par],"-s") == 0) {
			silent = 1;
			par++;
		} else if (strcmp(argv[par],"-d") == 0) {
			display = 1;
			par++;
		} else
			par++;
	}
	display = 1;
	if (!silent) {
		printf("Usage: %s <file_name> [-d][-s]\n", argv[0]);
		printf("\nParameters:\n");
		printf("\t-d : displays both input and output\n");
		printf("\t-s : silent\n");
		printf("\n");
	}

	if (strlen(filename) == 0) {
		printf("Missing dataset file name!\n");
		exit(0);
	}

	T = load_input(filename, &n, &d, &m);

	if (!silent && display) {
		printf("\nInput dataset:\n");
		for (i = 0; i < n*(d); i++) {
			if (i % (d) == 0)
				printf("\n");
			printf("%.2f ",T[i]);
		}
		printf("\n\n");
	}

	if (!silent)
		printf("Executing FCNN: %d examples, %d attributes, %d classes...\n", n, d, m);

	clock_t t = clock();
	int Sn = 0;
 	SUBSETID Sid = fcnn32(T, n, d, m, &Sn);

	t = clock() - t;

	if (!silent)
		printf("\nExecution time = %.3f seconds\n", ((float)t)/CLOCKS_PER_SEC);
	else
		printf("%.3f\n", ((float)t)/CLOCKS_PER_SEC);

	if (!silent && display) {
		printf("\nCondensed dataset:\n");
		for (i = 0; i < Sn; i++) {
			for (j = 0; j < d; j++)
				printf("%f ", T[Sid[i]*(d)+j]);
			printf("\n");
		}
	}
	printf("\nCondensed dataset size: %i\n",Sn);
	save_output(Sid,Sn);


	return 0;
}
