#include <atomic>
#include <chrono>
#include <cstdio>
#include <limits>
#include <mutex>
#include <vector>

struct W { std::atomic<unsigned> references{0}; };

int main() {
  const int N = 6, ITER = 20000000;
  std::vector<W> ws(N);
  std::mutex m;
  // 锁内自增：模拟临界区
  auto t0 = std::chrono::steady_clock::now();
  unsigned s = 0;
  for (int i = 0; i < ITER; ++i) {
    unsigned mn = std::numeric_limits<unsigned>::max(); int best = -1;
    m.lock();
    for (int k = 0; k < N; ++k) { unsigned v = ws[k].references.load(); if (v < mn) { mn = v; best = k; } }
    ++ws[best].references;
    s += best;
    m.unlock();
  }
  auto t1 = std::chrono::steady_clock::now();
  printf("锁内自增: %.1f ns/次 (sum=%u)\n", std::chrono::duration<double, std::nano>(t1-t0).count()/ITER, s);

  for (int k = 0; k < N; ++k) ws[k].references.store(0);
  s = 0;
  t0 = std::chrono::steady_clock::now();
  for (int i = 0; i < ITER; ++i) {
    unsigned mn = std::numeric_limits<unsigned>::max(); int best = -1;
    m.lock();
    for (int k = 0; k < N; ++k) { unsigned v = ws[k].references.load(); if (v < mn) { mn = v; best = k; } }
    m.unlock();
    ++ws[best].references;
    s += best;
  }
  t1 = std::chrono::steady_clock::now();
  printf("锁外自增: %.1f ns/次 (sum=%u)\n", std::chrono::duration<double, std::nano>(t1-t0).count()/ITER, s);
}
