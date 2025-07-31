/* Include the system headers we need */
#include <stdlib.h>
#include <stdio.h>

/* Include our header */
#include "ex7_vector.h"

/* Define what our struct is */
struct vector_t {
    size_t size;
    int *data;
};

/* Utility function to handle allocation failures. In this
   case we print a message and exit. */
static void allocation_failed() {
    fprintf(stderr, "Out of memory.\n");
    exit(1);
}

/* Bad example of how to create a new vector */
vector_t *bad_vector_new() {
    /* Create the vector and a pointer to it */
    vector_t *retval, v;
    retval = &v;

    /* Initialize attributes */
    retval->size = 1;
    retval->data = malloc(sizeof(int));
    if (retval->data == NULL) {
        allocation_failed();
    }

    retval->data[0] = 0;
    return retval;
}

/* Create a new vector with a size (length) of 1 and set its single component to zero... the
   right way */
vector_t *vector_new() {
    /* Declare what this function will return */
    vector_t *retval;

    /* First, we need to allocate memory on the heap for the struct */
    retval = /* YOUR CODE HERE */ malloc(sizeof(struct vector_t));

    /* Check our return value to make sure we got memory */
    if (/* YOUR CODE HERE */ retval == NULL) {
        allocation_failed();
    }

    /* Now we need to initialize our data.
       Since retval->data should be able to dynamically grow,
       what do you need to do? */
    retval->size = /* YOUR CODE HERE */ 1;
    retval->data = /* YOUR CODE HERE */ malloc(retval->size * sizeof(int));

    /* Check the data attribute of our vector to make sure we got memory */
    if (/* YOUR CODE HERE */ retval->data == NULL) {
        free(retval);				//Why is this line necessary?
        allocation_failed();
    }

    /* Complete the initialization by setting the single component to zero */
    /* YOUR CODE HERE */ retval->data[0] = 0;

    /* and return... */
    return retval; /* UPDATE RETURN VALUE */
}

/* Return the value at the specified location/component "loc" of the vector */
int vector_get(vector_t *v, size_t loc) {

    /* If we are passed a NULL pointer for our vector, complain about it and exit. */
    if(v == NULL) {
        fprintf(stderr, "vector_get: passed a NULL vector.\n");
        abort();
    }

    /* If the requested location is higher than we have allocated, return 0.
     * Otherwise, return what is in the passed location.
     */
    if (loc >= v->size) return 0;
    return v->data[loc];
    return 0;
}

/* Free up the memory allocated for the passed vector.
   Remember, you need to free up ALL the memory that was allocated. */
void vector_delete(vector_t *v) {
    /* YOUR CODE HERE */
    if (v == NULL) {
        fprintf(stderr, "vector_delete: passed a NULL vector.\n");
        return; // Nothing to delete
    }
    if (v->data != NULL) {
        free(v->data); // Free the data array
    }
    free(v); // Free the vector struct itself
    /*  Note: Setting v to NULL here does not affect the caller's pointer,
        as it is passed by value. The caller's pointer will still point to the
        original memory location, which is now freed.
        This is why it's a good practice to set the pointer to NULL after freeing,
        but it won't change the caller's pointer.
        If you want to ensure the caller's pointer is set to NULL, you would need
        to pass a pointer to the pointer (i.e., a double pointer) or return the
        pointer and assign it in the caller.
        Example of setting the caller's pointer to NULL:
        ```
            void vector_delete(vector_t **v) {
                if (v == NULL || *v == NULL) return; // Check for NULL pointer
                if ((*v)->data != NULL) {
                    free((*v)->data); // Free the data array
                }
                free(*v); // Free the vector struct itself
                *v = NULL; // Set the caller's pointer to NULL
            }
        ```
        This way, the caller's pointer will be set to NULL after deletion.
        Note: The above comment is just an explanation of how to handle the pointer
        in a way that the caller's pointer is also updated. The original function
        does not do this, so the caller's pointer will still point to the freed memory.
        This can lead to undefined behavior if the caller tries to access the freed memory.
        Always ensure to handle pointers carefully to avoid memory leaks or segmentation faults. */
}

/* Set a value in the vector, allocating additional memory if necessary. 
   If the extra memory allocation fails, call allocation_failed(). */
void vector_set(vector_t *v, size_t loc, int value) {
    if (loc >= v->size) {
        v->data = realloc(v->data, (loc + 1) * sizeof(int));
        if (v->data == NULL) {
            allocation_failed();
        }
        for (size_t i = v->size; i < loc; i++) {
            v->data[i] = 0;
        }
        v->size = loc + 1;
    }
    v->data[loc] = value;
}
