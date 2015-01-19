#include <iostream>
#include <iomanip>
#include <vector>

using namespace std;

struct Point {
    int row;
    int col;
};

ostream& operator << (ostream& os, const Point& p) {
    os << "[" << p.row << "," << p.col << "]";
    return os;
}

/**
 Smallest and fastest 2d array implementation. No checks. Nothing ;)
 */
template<class T>
class Array2 {
public:
    Array2(unsigned rows,unsigned cols)
    : rows_(rows), cols_(cols), data_(new T[rows*cols])
    {
    }

    T& at(unsigned row, unsigned col) {
        return data_[row*cols_ + col];
    }

    template<class P>
    T& at(const P& p) {
        return at(p.row, p.col);
    }

    const T& at(unsigned row, unsigned col) const {
        return data_[row*cols_ + col];
    }

    void fill(const T& value) {
        for( unsigned i=0; i<rows_*cols_; i++)
            data_[i] = value;
    }

    unsigned rows() const { return rows_; }
    unsigned cols() const { return cols_; }

    ~Array2() {
        delete data_;
    }

private:
    Array2(const Array2&& copy) {}

    unsigned rows_, cols_;
    T* data_;
};

template <class T>
ostream& operator <<(ostream& os,const Array2<T>& arr) {
    for( unsigned i=0; i<arr.rows(); i++ ) {
        for( unsigned j=0; j<arr.cols(); j++ ) {
            os << setw(3) << arr.at(i,j);
        }
        os << endl;
    }
    return os;
}

static Point move_shifts[] = { {-2, +1}, {-1, +2}, {+1, +2}, {+2, +1}, {+2, -1}, {+1, -2}, {-1, -2},  {-2, -1} };
static unsigned move_count = 8;

class KM {
public:
    KM(unsigned rank)
    : rank_(rank), board_(rank, rank)
    {
    }

    bool solve() {
        board_.fill(0);
        depth_ = 0;
        goal_ = rank_*rank_;
        return step( {0, 0} );
    }

    const Array2<unsigned>& board() const { return board_; }
private:

    bool step(const Point& p) {
        board_.at(p) = ++depth_;
        if( depth_ >= goal_ )
            return true;
        for( Point m: moves(p) ) {
            if( step(m) )
                return true;
        }
        board_.at(p) = 0;
        depth_--;
        return false;
    }

    vector<Point> moves(const Point& pos) {
        vector<Point> mm;
        for( unsigned i=0; i<move_count; i++ ) {
            // Optimizing the bottleneck:
            const Point& m = move_shifts[i];
            int r = pos.row + m.row;
            if( r >= 0 && r < rank_ ) {
                int c = pos.col + m.col;
                if( c >= 0 && c < rank_ && board_.at(r,c) == 0 ) {
                    mm.push_back({r,c});
                }
            }
        }
        return mm;
    }

    unsigned rank_, depth_, goal_;
    Array2<unsigned> board_;
};

template<class S>
void timing(const S& name,int repetitions, const std::function<void(void)>& block) {
    clock_t start = clock();
    while( repetitions-- > 0) {
        block();
    }
    cout << name << ": " << ((clock() - start)/((double)CLOCKS_PER_SEC)) << endl;
}

int main(int argc, char** argv) {
    cout << "starting\n";
    timing( "C++", 5, [] {
        KM km(7);
        km.solve();
//        cout << km.board() << endl;
    });
}

