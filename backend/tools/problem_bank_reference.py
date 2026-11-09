# 파일 역할: 문제은행 생성에 활용하는 기준 풀이 모음
# 참고: 이 주석은 코드 실행에 영향을 주지 않으며 각 함수의 입출력·책임을 설명합니다.
"""Maintenance reference solver; never exposed by a student API."""
import math
import bisect
import heapq
from collections import deque


# solve: solve 처리 결과를 생성하거나 반환합니다.
def solve(key, text):
    tokens = text.split()
    ints = lambda: list(map(int, tokens))
    if key in ('add', 'subtract', 'multiply', 'compare', 'gcd'):
        a, b = ints()
        if key == 'add': return str(a + b)
        if key == 'subtract': return str(a - b)
        if key == 'multiply': return str(a * b)
        if key == 'compare': return '<' if a < b else '>' if a > b else '=='
        return str(math.gcd(a, b))
    if key in ('parity', 'sum_n', 'times', 'factorial', 'prime', 'fibonacci', 'stairs', 'bit_count'):
        n = int(tokens[0])
        if key == 'parity': return 'Even' if n % 2 == 0 else 'Odd'
        if key == 'sum_n': return str(n * (n + 1) // 2)
        if key == 'times': return ' '.join(str(n * k) for k in range(1, 10))
        if key == 'factorial': return str(math.factorial(n))
        if key == 'prime':
            return 'YES' if n >= 2 and all(n % d for d in range(2, math.isqrt(n) + 1)) else 'NO'
        if key == 'bit_count': return str(n.bit_count())
        a, b = (0, 1) if key == 'fibonacci' else (1, 1)
        for _ in range(n): a, b = b, a + b
        return str(a)
    if key in ('reverse', 'palindrome', 'brackets'):
        s = text.rstrip('\r\n')
        if key == 'reverse': return s[::-1]
        if key == 'palindrome': return 'YES' if s == s[::-1] else 'NO'
        depth = 0
        for ch in s:
            depth += 1 if ch == '(' else -1
            if depth < 0: return 'NO'
        return 'YES' if depth == 0 else 'NO'
    if key == 'longest_word':
        n = int(tokens[0]); words = tokens[1:]
        assert len(words) == n
        return max(words, key=len)
    if key in ('maximum', 'minimum', 'average', 'array_sum', 'count', 'sort', 'unique', 'binary_search', 'lis', 'max_subarray'):
        n = int(tokens[0]); values = list(map(int, tokens[1:1+n]))
        assert len(values) == n
        if key == 'maximum': return str(max(values))
        if key == 'minimum': return str(min(values))
        if key == 'average': return format(sum(values) / n, '.12g')
        if key == 'array_sum': return str(sum(values))
        if key == 'count': return str(values.count(int(tokens[n+1])))
        if key == 'sort': return ' '.join(map(str, sorted(values)))
        if key == 'unique': return ' '.join(map(str, sorted(set(values))))
        if key == 'binary_search':
            target = int(tokens[n+1]); index = bisect.bisect_left(values, target)
            return str(index if index < n and values[index] == target else -1)
        if key == 'lis':
            tails = []
            for value in values:
                index = bisect.bisect_left(tails, value)
                if index == len(tails): tails.append(value)
                else: tails[index] = value
            return str(len(tails))
        best = current = values[0]
        for value in values[1:]:
            current = max(value, current + value); best = max(best, current)
        return str(best)
    if key in ('bfs', 'components'):
        data = ints(); n, m = data[:2]; edges = data[2:]; assert len(edges) == 2*m
        graph = [[] for _ in range(n)]
        for a, b in zip(edges[::2], edges[1::2]):
            graph[a-1].append(b-1); graph[b-1].append(a-1)
        if key == 'bfs':
            distance = [-1] * n; distance[0] = 0; queue = deque([0])
            while queue:
                node = queue.popleft()
                for neighbor in graph[node]:
                    if distance[neighbor] < 0:
                        distance[neighbor] = distance[node]+1; queue.append(neighbor)
            return str(distance[-1])
        seen = set(); components = 0
        for start in range(n):
            if start in seen: continue
            components += 1; seen.add(start); stack = [start]
            while stack:
                for neighbor in graph[stack.pop()]:
                    if neighbor not in seen: seen.add(neighbor); stack.append(neighbor)
        return str(components)
    if key == 'coins':
        n, target = map(int, tokens[:2]); coins = list(map(int, tokens[2:])); assert len(coins) == n
        dp = [0] + [target+1]*target
        for amount in range(1, target+1):
            for coin in coins:
                if coin <= amount: dp[amount] = min(dp[amount], dp[amount-coin]+1)
        return str(dp[target] if dp[target] <= target else -1)
    if key == 'josephus':
        n, k = ints(); queue = deque(range(1, n+1)); result = []
        while queue:
            queue.rotate(-(k-1)); result.append(queue.popleft())
        return ' '.join(map(str, result))
    if key == 'prefix_sum':
        data = ints(); n, q = data[:2]; values = data[2:2+n]; queries = data[2+n:]; assert len(queries) == 2*q
        prefix = [0]
        for value in values: prefix.append(prefix[-1]+value)
        return '\n'.join(str(prefix[r]-prefix[l-1]) for l, r in zip(queries[::2], queries[1::2]))
    if key == 'maze':
        n, m = map(int, tokens[:2]); grid = tokens[2:]; assert len(grid) == n and all(len(row) == m for row in grid)
        if grid[0][0] == '0' or grid[-1][-1] == '0': return '-1'
        distance = [[-1]*m for _ in range(n)]; distance[0][0] = 1; queue = deque([(0,0)])
        while queue:
            r, c = queue.popleft()
            for dr, dc in [(1,0),(-1,0),(0,1),(0,-1)]:
                nr, nc = r+dr, c+dc
                if 0 <= nr < n and 0 <= nc < m and grid[nr][nc] == '1' and distance[nr][nc] < 0:
                    distance[nr][nc] = distance[r][c]+1; queue.append((nr,nc))
        return str(distance[-1][-1])
    if key == 'meetings':
        data = ints(); n = data[0]; pairs = list(zip(data[1::2],data[2::2])); assert len(pairs)==n
        end = -1; count = 0
        for start, finish in sorted(pairs, key=lambda p: (p[1],p[0])):
            if start >= end: count += 1; end = finish
        return str(count)
    if key == 'stack':
        lines = text.splitlines(); n = int(lines[0]); commands = lines[1:]; assert len(commands)==n
        stack = []; result = []
        for command in commands:
            parts = command.split(); name = parts[0]
            if name == 'push': stack.append(int(parts[1]))
            elif name == 'pop': result.append(str(stack.pop() if stack else -1))
            elif name == 'top': result.append(str(stack[-1] if stack else -1))
            elif name == 'size': result.append(str(len(stack)))
            elif name == 'empty': result.append('0' if stack else '1')
        return '\n'.join(result)
    raise ValueError(key)
