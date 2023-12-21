#include <iostream>
#include <thread>
#include <vector> // is like list of python
#include <chrono> // deal with time

// A CPU-bound task that performs heavy computations
void cpu_intensive_task() {
    // Perform a large number of additions to simulate work
    volatile long long sum = 0; // volatile to prevent optimizations that could eliminate the loop
    for (long long i = 0; i < 1000000000; ++i) {
        sum += i;
    }
    std::cout << "Task completed, sum: " << sum << std::endl;
}

int main() {
    const int num_threads = 16; // Number of threads to use
    std::vector<std::thread> threads; // Vector to hold all threads

    // Measure time with threading
    auto start = std::chrono::high_resolution_clock::now();
    
    // Start multiple threads to perform the task concurrently
    for (int i = 0; i < num_threads; ++i) {
        threads.emplace_back(cpu_intensive_task); // emplace_back --> adds an element to end of vector
    }                                             // cpu_intensive_task --> creates a new thread that begins executed by calling cpu_intensive_task()

    // Wait for all threads to complete before calling the main thread
    for (auto& t : threads) { // for each element in 'threads' vector. auto --> machine to deduce the type. & --> reference to actual 'threads', not a copy of it. t--> each element is referred to as 't'
        t.join(); // .join() waits for its associated threads to complete its tasks before calling the main thread()
    }

    // Stop measuring time
    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> diff = end - start;
    std::cout << "Time taken with threading: " << diff.count() << " seconds" << std::endl;

    // Measure time without threading
    start = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < num_threads; ++i) {
        cpu_intensive_task(); // Run task sequentially on the main thread
    }
    end = std::chrono::high_resolution_clock::now();

    diff = end - start;
    std::cout << "Time taken without threading: " << diff.count() << " seconds" << std::endl;

    return 0;
}
