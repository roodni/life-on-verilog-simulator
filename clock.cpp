#include <iostream>
#include <thread>
#include <chrono>
using namespace std;

int main() {
    cerr << "waiting..." << endl;
    this_thread::sleep_for(chrono::seconds(3));
    for (;;) {
        this_thread::sleep_for(chrono::milliseconds(500));
        cout << 'x' << flush;
    }
}