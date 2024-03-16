package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodGet {
			// Respond with a 200 status code
			w.WriteHeader(http.StatusOK)
			fmt.Fprintf(w, "OK")
		} else {
			// Respond with a 405 Method Not Allowed status code for non-GET requests
			w.WriteHeader(http.StatusMethodNotAllowed)
			fmt.Fprintf(w, "Method Not Allowed")
		}
	})

	// Start the server on port 8080
	fmt.Println("Server listening on port 8080")
	if err := http.ListenAndServe(":8080", nil); err != nil {
        log.Fatal(err)
    }
}
