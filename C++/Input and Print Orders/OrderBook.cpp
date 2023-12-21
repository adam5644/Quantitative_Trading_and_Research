#include "OrderBook.h"
#include <iostream>

void OrderBook::addOrder(const Order& order){
    orders.push_back(order);
}

void OrderBook::printOrders() const {
    for (const auto& order : orders){
        std::cout << "ID: " << order.price
                  << ", Price: $" <<order.price
                  << ", Quantity: "<<order.quantity
                  << ", Type: "<<(order.isBuyOrder ? "Buy" : "Sell") << '\n'; 
    }
}