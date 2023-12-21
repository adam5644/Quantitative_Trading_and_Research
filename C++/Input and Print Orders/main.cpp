#include <iostream>
#include "OrderBook.h"
#include <limits> // part of cpp standard library. Contains templated class "std::numeric_limits", which contains information about the properties of arithmetic types.

int main() {

    // ask user for inputs
    OrderBook book;
    std::cout << "Enter orders (ID, Price, Quantity, Type), type -1 to end:\n";

    while (true){
        Order newOrder;
        std::cout << "Enter ID: ";
        std::cin >> newOrder.id;
        if (newOrder.id == -1) break; 
    
        std::cout << "Enter Price: ";
        std::cin >> newOrder.price;
        std::cout << "Enter Quantity: ";
        std::cin >> newOrder.quantity;
        std::cout << "Type (1 for Buy, 0 for Sell): ";
        int type;
        std:: cin >> type;
        newOrder.isBuyOrder = type;

        book.addOrder(newOrder);
    
    } 

    // after user inputted, print final orders 
    std::cout << "\nFinal Order Book:\n";
    book.printOrders();

    // add a pause to prevent console window of .exe file from close immediately after the program finished execution
    std::cout << "Press ENTER to continue...";
    
    std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
    // (q) whats "std::numeric_limits"?
    // (a)
    // templated class "std::numeric_limits", which contains information about the properties of arithmetic types.
    // get max and min values that can be held by a type, e.g. std::numeric_limits<int>::max()
    
    return 0; // return 0 if program terminates successfully


}