// 统一测试：锁外 vs 锁内自增，多种抢占窗口
#include <atomic>
#include <chrono>
#include <cstdio>
#include <limits>
#include <mutex>
#include <thread>
#include <vector>

static constexpr int W = 6, N = 10, TRIALS = 300;

int main() {
  for (int inside = 0; inside <= 1; ++inside) {
    for (int delay_us : {0, 5, 50}) {
      int all_same = 0, worst = 0; long pile = 0;
      for (int t = 0; t < TRIALS; ++t) {
        std::atomic<unsigned> refs[W];
        for (int i = 0; i < W; ++i) refs[i].store(0);
        std::mutex m;
        std::vector<int> picked(N, -1);
        std::atomic<int> ready{0};
        std::atomic<bool> go{false};
        std::vector<std::thread> th;
        for (int i = 0; i < N; ++i) th.emplace_back([&, i] {
          ready.fetch_add(1);
          while (!go.load()) {}
          unsigned mn = std::numeric_limits<unsigned>::max(); int best = -1;
          m.lock();
          for (int k = 0; k < W; ++k) { unsigned v = refs[k].load(); if (v < mn) { mn = v; best = k; } }
          if (inside) ++refs[best];
          m.unlock();
          if (!inside) {
            if (delay_us) std::this_thread::sleep_for(std::chrono::microseconds(delay_us));
            ++refs[best];
          }
          picked[i] = best;
        });
        while (ready.load() < N) {}
        go.store(true);
        for (auto& x : th) x.join();
        int cnt[W] = {};
        for (int i = 0; i < N; ++i) cnt[picked[i]]++;
        int mx = 0;
        for (int i = 0; i < W; ++i) if (cnt[i] > mx) mx = cnt[i];
        if (mx == N) all_same++;
        pile += mx; if (mx > worst) worst = mx;
      }
      printf("%s 窗口=%2dus : 全撞一个=%3d/%d (%5.1f%%)  平均最大堆积=%4.2f  最坏=%2d/%d\n",
             inside ? "锁内" : "锁外", delay_us,
             all_same, TRIALS, 100.0*all_same/TRIALS, (double)pile/TRIALS, worst, N);
    }
  }
}
