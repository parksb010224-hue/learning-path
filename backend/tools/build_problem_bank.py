# 파일 역할: 정해진 문제 데이터로 테스트케이스와 문제은행을 생성
# 참고: 이 주석은 코드 실행에 영향을 주지 않으며 각 함수의 입출력·책임을 설명합니다.
"""Generate an idempotent MariaDB enrichment script and an auditable bank."""
import json
from pathlib import Path
from problem_bank_reference import solve

ROOT = Path(__file__).resolve().parents[1]
BANK = []

# array: array 처리 결과를 생성하거나 반환합니다.
def array(values): return str(len(values))+'\n'+' '.join(map(str, values))
# target_array: target array 처리 결과를 생성하거나 반환합니다.
def target_array(values, target): return array(values)+'\n'+str(target)
# graph: graph 처리 결과를 생성하거나 반환합니다.
def graph(n, edges): return f'{n} {len(edges)}'+''.join(f'\n{a} {b}' for a,b in edges)
# query_array: query array 처리 결과를 생성하거나 반환합니다.
def query_array(values, queries): return f'{len(values)} {len(queries)}\n'+ ' '.join(map(str,values))+''.join(f'\n{l} {r}' for l,r in queries)
# meetings: meetings 처리 결과를 생성하거나 반환합니다.
def meetings(pairs): return str(len(pairs))+''.join(f'\n{a} {b}' for a,b in pairs)
# commands: commands 처리 결과를 생성하거나 반환합니다.
def commands(lines): return str(len(lines))+'\n'+'\n'.join(lines)
# maze: maze 처리 결과를 생성하거나 반환합니다.
def maze(rows): return f'{len(rows)} {len(rows[0])}\n'+'\n'.join(rows)

# add: add 처리 결과를 생성하거나 반환합니다.
def add(key,title,difficulty,category,description,input_desc,output_desc,pattern,inputs,mode='exact'):
    inputs=list(dict.fromkeys(inputs))
    assert len(inputs)>=9,(key,len(inputs))
    BANK.append(dict(seed_no=len(BANK)+1,key=key,title=title,difficulty=difficulty,category=category,
        description=description,input_desc=input_desc,output_desc=output_desc,input_pattern=pattern,output_mode=mode,
        cases=[dict(input_data=text,expected_output=solve(key,text),is_sample=i<2) for i,text in enumerate(inputs)]))

pair_inputs=['1 2','10 20','-1 5','0 0','0 7','9 0','-8 -3','7 -9','1000000000 1000000000','-1000000000 1000000000','42 42','-4 -4']
for key,title,op in [('add','A+B','합'),('subtract','A-B','차(A-B)'),('multiply','A*B','곱')]:
    old={'add':['1 2','10 20','-1 5'],'subtract':['5 3','10 7','3 10'],'multiply':['2 3','5 5','-2 4']}[key]
    add(key,title,'Easy','구현',f'두 정수 A와 B의 {op}을 구하세요. 음수와 0도 입력될 수 있습니다.',
        '첫째 줄에 두 정수 A와 B가 공백으로 주어진다. -10^9 ≤ A, B ≤ 10^9.',f'{op}을 정수로 출력한다.','two_ints',old+pair_inputs)
add('compare','두 수 비교하기','Easy','조건문','두 정수 A와 B의 대소 관계를 비교하세요.',
    '-10^9 ≤ A, B ≤ 10^9인 두 정수가 첫째 줄에 공백으로 주어진다.','A<B이면 <, A>B이면 >, 같으면 ==를 출력한다.','two_ints',['3 5','7 2','4 4']+pair_inputs)
add('parity','짝수 홀수 판별','Easy','조건문','음수와 0을 포함한 정수가 짝수인지 홀수인지 판별하세요.',
    '첫째 줄에 정수 N이 주어진다. -10^9 ≤ N ≤ 10^9.','짝수이면 Even, 홀수이면 Odd를 출력한다.','one_int',list(map(str,[4,7,0,1,-1,-2,-7,1000000000,999999999,-1000000000])))
add('sum_n','1부터 N까지 합','Easy','반복문','1부터 N까지 모든 정수의 합을 구하세요. N이 0이면 합은 0입니다.',
    '첫째 줄에 정수 N이 주어진다. 0 ≤ N ≤ 100000.','합을 정수로 출력한다.','one_int',list(map(str,[5,10,100,0,1,2,3,999,10000,100000])))
add('times','구구단 출력','Easy','반복문','N×1부터 N×9까지의 결과를 순서대로 출력하세요.',
    '첫째 줄에 정수 N이 주어진다. 1 ≤ N ≤ 9.','아홉 개의 곱을 한 줄에 공백으로 구분해 출력한다. 수식은 출력하지 않는다.','one_int',list(map(str,[2,3,5,1,4,6,7,8,9])))
arrays=[[1,3,5,2,4],[10,20,30,40],[-1,-5,-3],[0],[7],[-9,-9],[-10,-1,0,100],[5]*20,[1000000000,-1000000000],list(range(-500,500))]
for key,title in [('maximum','최댓값 찾기'),('minimum','최솟값 찾기')]:
    add(key,title,'Easy','배열',f'배열의 {"최댓값" if key=="maximum" else "최솟값"}을 구하세요. 원소가 모두 음수이거나 중복될 수도 있습니다.',
        '첫째 줄에 N(1 ≤ N ≤ 1000), 둘째 줄에 N개의 정수(-10^9 이상 10^9 이하)가 주어진다.',
        '찾은 값을 정수로 출력한다.','count_int_list',[array(a) for a in arrays])
add('average','평균 구하기','Easy','배열','배열의 산술평균을 구하세요. 정수 나눗셈이 아닌 실제 평균을 계산해야 합니다.',
    '첫째 줄에 N(1 ≤ N ≤ 1000), 둘째 줄에 N개의 정수(-10^9 이상 10^9 이하)가 주어진다.',
    '평균을 출력한다. 정수/소수 표기는 모두 허용하며 절대 오차 또는 상대 오차 10^-6 이내면 정답이다.',
    'count_int_list',[array(a) for a in [[10,20,30,40,50],[1,2,3],[5,5,5,5],[0],[-7],[1,2],[0,0,2],[-1,0],[-3,-2,-2],[1000000000,-1000000000],list(range(1000))]],'float')
strings=['hello','abcde','level','a','ab','Aa','Ab123','a'*1000,'0123456789','ZyxWV']
add('reverse','문자열 뒤집기','Medium','문자열','문자열의 문자 순서를 거꾸로 출력하세요. 대소문자를 그대로 유지합니다.',
    '영문 대소문자와 숫자로 이루어진 길이 1~1000의 공백 없는 문자열 S가 한 줄에 주어진다.',
    'S를 뒤집은 문자열을 출력한다.','string',strings)
add('factorial','팩토리얼','Medium','재귀','0!은 1이고 N!은 1부터 N까지의 곱입니다. N!을 구하세요.',
    '첫째 줄에 정수 N이 주어진다. 0 ≤ N ≤ 20.','N!의 정확한 정수 값을 출력한다.','one_int',list(map(str,[5,3,0,1,2,4,7,10,15,20])))
add('array_sum','배열 합 구하기','Medium','배열','배열의 모든 원소를 더하세요. 음수와 0이 포함될 수 있습니다.',
    '첫째 줄에 N(1 ≤ N ≤ 1000), 둘째 줄에 N개의 정수(-10^9 이상 10^9 이하)가 주어진다.',
    '모든 원소의 합을 정수로 출력한다.','count_int_list',[array(a) for a in [[1,2,3,4,5],[10,20,30,40],[-1,2,-3]]+arrays])
count_inputs=[target_array(a,t) for a,t in [([1,2,2,3,2],2),([1,1,1,1],1),([1,2,3,4,5],6),([0],0),([0],1),([-1,-2,-1],-1),([7]*100,7),(list(range(1000)),999),([1,2,3],1),([5,5,5],0)]]
add('count','특정 숫자 개수 세기','Medium','배열','배열에서 찾을 값 X의 등장 횟수를 구하세요.',
    '첫째 줄 N(1~1000), 둘째 줄 N개의 정수, 셋째 줄 X가 주어진다. 원소와 X는 -10^9 이상 10^9 이하이다.',
    'X의 등장 횟수를 출력한다. 없으면 0을 출력한다.','count_list_target',count_inputs)
add('palindrome','팰린드롬 판별','Medium','문자열','문자열이 앞에서 읽어도 뒤에서 읽어도 같은지 판별하세요. 대소문자는 구분합니다.',
    '영문 대소문자와 숫자로 이루어진 길이 1~1000의 공백 없는 문자열 S가 주어진다.',
    '팰린드롬이면 YES, 아니면 NO를 출력한다.','string',['level','hello','abcba','a','aa','ab','Aa','1221','1231','x'*1000,'a'+'b'*998+'a'])
sort_arrays=[[5,2,4,1,3],[10,7,8,9],[3,3,1],[1],[2,1],[0,0,0],[-3,4,-2,0],[5]*100,list(range(1000,0,-1)),[-1000000000,1000000000,0]]
add('sort','정렬하기','Medium','정렬','배열을 오름차순으로 정렬하세요. 중복된 원소는 개수를 유지합니다.',
    '첫째 줄 N(1~1000), 둘째 줄 N개의 정수(-10^9 이상 10^9 이하)가 주어진다.',
    '정렬한 모든 원소를 한 줄에 공백으로 구분해 출력한다.','count_int_list',[array(a) for a in sort_arrays])
add('unique','중복 제거','Medium','배열','배열의 중복 원소를 제거한 뒤 오름차순으로 출력하세요. 처음 등장한 순서를 유지하는 문제가 아닙니다.',
    '첫째 줄 N(1~1000), 둘째 줄 N개의 정수(-10^9 이상 10^9 이하)가 주어진다.',
    '서로 다른 원소를 오름차순으로 한 줄에 공백으로 구분해 출력한다.','count_int_list',[array(a) for a in [[1,2,2,3,3,4],[5,5,5,5,5],[4,1,2,1]]+sort_arrays])
add('prime','소수 판별','Medium','수학','1보다 큰 정수 중 약수가 1과 자기 자신뿐인 수를 소수라고 합니다. N이 소수인지 판별하세요.',
    '첫째 줄에 정수 N이 주어진다. 0 ≤ N ≤ 10^9.','소수이면 YES, 아니면 NO를 출력한다.','one_int',list(map(str,[7,10,2,0,1,3,4,9,25,49,97,999983,1000000000])))
add('fibonacci','피보나치','Medium','DP','F(0)=0, F(1)=1, F(N)=F(N-1)+F(N-2)입니다. F(N)을 구하세요.',
    '첫째 줄에 정수 N이 주어진다. 0 ≤ N ≤ 90.','F(N)의 정확한 정수 값을 출력한다. 나머지 연산을 하지 않는다.','one_int',list(map(str,[5,7,0,1,2,3,10,30,60,90])))
word_sets=[['apple','banana','watermelon','kiwi'],['cat','elephant','dog'],['a','ab','abc','abcd','abcde'],['a'],['ab','cd','ef'],['long','tiny','wide'],['z','zz','Z'],['x'*100,'b'],['same','same'],['a']*998+['bbbb','cccc']]
add('longest_word','가장 긴 단어 찾기','Medium','문자열','가장 긴 단어를 찾으세요. 가장 긴 길이가 같은 단어가 여러 개면 입력에서 가장 먼저 등장한 단어를 출력합니다.',
    '첫째 줄 N(1~1000), 둘째 줄에 영문 대소문자로 된 N개의 단어가 주어진다. 각 단어 길이는 1~100이다.',
    '선택한 단어 하나를 출력한다.','count_words',[str(len(a))+'\n'+' '.join(a) for a in word_sets])
graphs=[(4,[(1,2),(2,3),(3,4),(1,4)]),(5,[(1,2),(2,3),(3,4),(4,5)]),(3,[(1,2)]),(1,[]),(4,[]),(2,[(1,2)]),(4,[(1,2),(2,1),(2,3),(3,4)]),(4,[(1,1),(1,2),(2,4)]),(1000,[(1,2)]*5000),(1000,[(i,i+1) for i in range(1,1000)])]
add('bfs','BFS 최단 거리','Hard','그래프','무방향 비가중 그래프에서 1번 정점부터 N번 정점까지 이동하는 최소 간선 수를 구하세요. 시작과 도착이 같으면 거리는 0입니다.',
    '첫째 줄 N(1~1000), M(0~5000). 다음 M줄에 간선 양 끝점 A, B(1~N)가 주어진다. 중복 간선과 자기 자신으로 향하는 간선도 허용한다.',
    '최소 간선 수를 출력한다. 도달할 수 없으면 -1을 출력한다.','graph_edges',[graph(n,e) for n,e in graphs])
add('components','DFS 연결 요소 개수','Hard','그래프','무방향 그래프의 연결 요소 개수를 구하세요. 다른 정점과 연결되지 않은 정점도 연결 요소 하나입니다.',
    '첫째 줄 N(1~1000), M(0~5000). 다음 M줄에 A, B(1~N)가 주어진다. 중복 간선과 자기 자신으로 향하는 간선도 허용한다.',
    '연결 요소 개수를 출력한다.','graph_edges',[graph(5,[(1,2),(2,3),(4,5)]),graph(4,[(1,2),(3,4)]),graph(3,[])]+[graph(n,e) for n,e in graphs])
add('stairs','계단 오르기 DP','Hard','DP','한 번에 1칸 또는 2칸씩 올라 정확히 N번째 계단에 도착하는 방법 수를 구하세요. 이동 순서가 다르면 다른 방법입니다. N=0은 움직이지 않는 한 가지 방법입니다.',
    '첫째 줄에 정수 N이 주어진다. 0 ≤ N ≤ 90.','경우의 수를 정확한 정수로 출력한다.','one_int',list(map(str,[3,5,1,0,2,4,10,30,60,90])))
coin_sets=[(15,[1,5,12]),(7,[2,4]),(6,[1,3,4]),(0,[2,5]),(1,[2]),(12,[5,1,2]),(8,[2,2,4]),(7,[7]),(11,[5,7]),(10000,[1,7,23])]
add('coins','동전 거스름돈','Hard','DP','각 동전을 무제한으로 사용할 수 있을 때 정확히 목표 금액 K를 만드는 최소 동전 수를 구하세요. 탐욕적으로 가장 큰 동전부터 고르는 방법이 항상 정답은 아닙니다.',
    '첫째 줄 N(1~10), K(0~10000). 둘째 줄에 N개의 양의 동전 값(1~1000)이 공백으로 주어진다. 같은 값이 여러 번 나올 수 있다.',
    '최소 동전 수를 출력한다. 만들 수 없으면 -1, K=0이면 0을 출력한다.','coin_change',[f'{len(a)} {k}\n'+ ' '.join(map(str,a)) for k,a in coin_sets])
add('brackets','괄호 검사','Hard','스택','소괄호 문자열이 올바른 괄호 문자열인지 판별하세요. 빈 문자열도 올바른 문자열로 봅니다.',
    '첫째 줄에 (와 )로 이루어진 길이 0~1000의 문자열이 주어진다. 빈 문자열은 빈 줄로 입력된다.',
    '올바르면 YES, 아니면 NO를 출력한다.','string',['()()','(())','(()',')(','(',')','\n','()','())(','('*500+')'*500,'('*500+')'*499])
# Ten additional problems.
add('gcd','최대공약수','Easy','수학','두 음이 아닌 정수의 최대공약수를 구하세요. 한 수가 0이면 다른 수가 답이고, 두 수가 모두 0이면 0을 출력합니다.',
    '첫째 줄에 A, B가 주어진다. 0 ≤ A, B ≤ 10^9.','최대공약수를 출력한다.','two_ints',['12 18','7 13','0 0','0 9','9 0','1 1','1000000000 1000000000','54 24','48 180','999983 2'])
add('binary_search','이진 탐색','Medium','이진 탐색','오름차순으로 정렬된 배열에서 X가 처음 나타나는 인덱스를 찾으세요. 인덱스는 0부터 시작합니다.',
    '첫째 줄 N(1~1000), 둘째 줄 오름차순 정수 N개, 셋째 줄 X. 원소와 X는 -10^9 이상 10^9 이하이다.',
    'X의 첫 인덱스를 출력한다. 없으면 -1을 출력한다.','count_list_target',[target_array(a,t) for a,t in [([1,3,5,7,9],5),([1,2,2,2,4],2),([0],0),([0],1),([1,2,3],1),([1,2,3],3),([-5,-2,0],-2),([1]*50,1),(list(range(1000)),999),(list(range(1000)),1000)]])
add('josephus','요세푸스 순열','Medium','큐','1번부터 N번까지 원형으로 앉아 있습니다. 1번부터 세어 K번째 사람을 제거하고, 다음 사람부터 다시 K명을 셉니다. 제거 순서를 구하세요.',
    '첫째 줄에 N, K가 주어진다. 1 ≤ N, K ≤ 1000.','제거되는 사람 번호를 한 줄에 공백으로 구분해 출력한다. 꺾쇠와 쉼표는 출력하지 않는다.','two_ints',['7 3','5 2','1 1','1 1000','5 1','2 2','3 10','10 10','20 7','1000 999'])
queries=[([1,2,3,4,5],[(1,3),(2,5)]),([-1,2,-3],[(1,3),(2,2)]),([7],[(1,1)]),([0]*5,[(1,5),(5,5)]),([-5,-2],[(1,2),(1,1)]),([1,2,3],[(3,3),(1,1),(1,3)]),([10]*10,[(1,10),(4,7)]),([1000000000]*3,[(1,3)]),(list(range(1000)),[(1,1000),(500,500)]),([1,-1,1,-1],[(1,4),(2,3)]*500)]
add('prefix_sum','구간 합 구하기','Medium','누적합','배열이 주어질 때 여러 구간의 합을 구하세요. 구간 양 끝을 모두 포함하며 배열 인덱스는 1부터 시작합니다.',
    '첫째 줄 N, Q(각 1~1000), 둘째 줄 정수 N개(-10^9 이상 10^9 이하). 다음 Q줄에 L, R(1 ≤ L ≤ R ≤ N)이 주어진다.',
    '각 질의의 구간 합을 질의 순서대로 한 줄에 하나씩 출력한다.','prefix_queries',[query_array(a,q) for a,q in queries])
add('bit_count','이진수 1의 개수','Easy','비트 연산','음이 아닌 정수 N을 이진수로 나타냈을 때 1의 개수를 구하세요. 0의 답은 0입니다.',
    '첫째 줄에 정수 N이 주어진다. 0 ≤ N ≤ 2^63-1.','1의 개수를 출력한다.','one_int',list(map(str,[7,10,0,1,2,8,15,1024,2**63-1,2**62+1])))
lis_arrays=[[10,20,10,30,20,50],[3,2,1],[1],[1,1,1],[1,2,3,4],[-3,-2,-1],[0,-1,2,-3,4],[2,1,2,1,2],[5,1,6,2,7,3],list(range(1000))]
add('lis','최장 증가 부분 수열','Hard','DP','배열에서 순서를 유지하며 일부 원소를 선택해 엄격히 증가하는 가장 긴 부분 수열의 길이를 구하세요. 같은 값은 증가로 보지 않습니다. 연속할 필요는 없습니다.',
    '첫째 줄 N(1~1000), 둘째 줄 N개의 정수(-10^9 이상 10^9 이하)가 주어진다.',
    '최장 증가 부분 수열의 길이를 출력한다.','count_int_list',[array(a) for a in lis_arrays])
mazes=[['111','001','111'],['10','01'],['1'],['0'],['11111'],['1','1','1'],['11','11'],['01','11'],['11','10'],['1111','0101','1111','1001'],['1'*30 for _ in range(30)]]
add('maze','미로 최단 거리','Hard','그래프','1은 길, 0은 벽입니다. 왼쪽 위에서 오른쪽 아래까지 상하좌우로만 이동하는 최단 경로의 칸 수를 구하세요. 시작과 도착 칸도 셉니다.',
    '첫째 줄 N, M(각 1~30), 다음 N줄에 공백 없는 길이 M의 0/1 문자열이 주어진다.',
    '최단 경로의 칸 수를 출력한다. 시작/도착이 벽이거나 도달할 수 없으면 -1을 출력한다.','binary_grid',[maze(a) for a in mazes])
meeting_sets=[[(1,4),(3,5),(0,6),(5,7),(8,9),(5,9)],[(1,2),(2,3),(3,4)],[],[(0,1)],[(0,10),(1,2),(2,3)],[(1,3),(1,3),(3,5)],[(0,5),(1,5),(2,5)],[(2,4),(0,2),(4,6)],[(0,100),(1,3),(3,4),(4,5)],[(i,i+1) for i in range(1000)]]
add('meetings','회의실 배정','Hard','그리디','한 회의실에서 겹치지 않게 진행할 수 있는 최대 회의 수를 구하세요. 끝나는 시각에 다른 회의를 바로 시작할 수 있습니다.',
    '첫째 줄 N(0~1000), 다음 N줄에 시작 S와 종료 E(0 ≤ S < E ≤ 10^9)가 주어진다. 입력은 정렬되어 있지 않으며 같은 회의가 중복될 수 있다.',
    '선택할 수 있는 최대 회의 수를 출력한다. N=0이면 0이다.','pair_rows',[meetings(a) for a in meeting_sets])
max_arrays=[[-2,1,-3,4,-1,2,1,-5,4],[-5,-2,-8],[7],[-7],[0,0,0],[1,2,3],[-1,2,-1,2,-1],[5,-100,6],[1000000000]*3,list(range(-500,500))]
add('max_subarray','최대 부분배열 합','Medium','DP','연속한 원소를 하나 이상 선택했을 때 만들 수 있는 최대 합을 구하세요. 아무 원소도 선택하지 않는 것은 허용하지 않습니다.',
    '첫째 줄 N(1~1000), 둘째 줄 N개의 정수(-10^9 이상 10^9 이하)가 주어진다.',
    '최대 합을 정수로 출력한다. 모든 원소가 음수여도 하나 이상 선택해야 한다.','count_int_list',[array(a) for a in max_arrays])
stack_sets=[['push 3','push 5','top','size','pop','top'],['pop','top','size','empty'],['push 1'],['empty','push 0','empty','pop','empty'],['push -1','top','pop','pop'],['push 1','push 1','size','pop','size'],['size'],['top'],['push 1000000000','top','pop','empty'],['push 1']*997+['size','pop','top']]
add('stack','스택 명령 처리','Medium','스택','명령에 따라 정수 스택을 관리하세요. push X는 삽입, pop은 맨 위 값을 제거해 출력, top은 맨 위 값을 출력, size는 크기, empty는 비어 있으면 1 아니면 0을 출력합니다. 빈 스택의 pop/top은 -1입니다.',
    '첫째 줄 N(1~1000), 다음 N줄에 명령이 주어진다. push의 X는 -10^9 이상 10^9 이하이다.',
    'push를 제외한 명령마다 결과를 한 줄씩 출력한다. push만 있으면 아무것도 출력하지 않는다.','command_rows',[commands(a) for a in stack_sets])

assert len(BANK)==35

# sql_text: sql text 처리 결과를 생성하거나 반환합니다.
def sql_text(text): return "CONVERT(UNHEX('"+text.encode('utf-8').hex()+"') USING utf8mb4)"

# build: build 처리 결과를 생성하거나 반환합니다.
def build():
    data=ROOT/'data/problem_bank.json'
    data.write_text(json.dumps(BANK,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    lines=['-- MariaDB: existing users/submissions/AI data are preserved.',
      '-- Select the existing database before running. Run this once or repeat safely.',
      'SET NAMES utf8mb4;',
      'ALTER TABLE test_cases ADD COLUMN IF NOT EXISTS is_sample TINYINT(1) NOT NULL DEFAULT 0;',
      "ALTER TABLE problems ADD COLUMN IF NOT EXISTS output_mode VARCHAR(20) NOT NULL DEFAULT 'exact';",
      "ALTER TABLE problems ADD COLUMN IF NOT EXISTS input_pattern VARCHAR(40) NOT NULL DEFAULT '';",
      'DROP TEMPORARY TABLE IF EXISTS lp_problem_seed;',
      'DROP TEMPORARY TABLE IF EXISTS lp_case_seed;',
      'CREATE TEMPORARY TABLE lp_problem_seed (seed_no INT PRIMARY KEY, title VARCHAR(100), difficulty VARCHAR(30), category VARCHAR(50), description TEXT, input_desc TEXT, output_desc TEXT, output_mode VARCHAR(20), input_pattern VARCHAR(40)) DEFAULT CHARSET=utf8mb4;',
      'CREATE TEMPORARY TABLE lp_case_seed (seed_no INT, input_data TEXT, expected_output TEXT, is_sample TINYINT(1)) DEFAULT CHARSET=utf8mb4;']
    for problem in BANK:
      lines += [f"-- {problem['seed_no']}: {problem['title']}",
        'INSERT INTO lp_problem_seed VALUES ('+str(problem['seed_no'])+','+','.join(sql_text(problem[k]) for k in ['title','difficulty','category','description','input_desc','output_desc','output_mode','input_pattern'])+');']
      for case in problem['cases']:
        lines.append('INSERT INTO lp_case_seed VALUES ('+str(problem['seed_no'])+','+sql_text(case['input_data'])+','+sql_text(case['expected_output'])+','+str(int(case['is_sample']))+');')
    lines += ['START TRANSACTION;',
      '''INSERT INTO problems (title,difficulty,category,description,input_desc,output_desc,output_mode,input_pattern)
SELECT s.title,s.difficulty,s.category,s.description,s.input_desc,s.output_desc,s.output_mode,s.input_pattern
FROM lp_problem_seed s WHERE NOT EXISTS (SELECT 1 FROM problems p WHERE BINARY p.title = BINARY s.title);''',
      '''UPDATE problems p JOIN lp_problem_seed s ON BINARY p.title = BINARY s.title
SET p.difficulty=s.difficulty,p.category=s.category,p.description=s.description,p.input_desc=s.input_desc,p.output_desc=s.output_desc,p.output_mode=s.output_mode,p.input_pattern=s.input_pattern;''',
      '''UPDATE test_cases t JOIN problems p ON p.id=t.problem_id JOIN lp_problem_seed s ON BINARY p.title=BINARY s.title SET t.is_sample=0;''',
      '''UPDATE test_cases t JOIN problems p ON p.id=t.problem_id JOIN lp_problem_seed s ON BINARY p.title=BINARY s.title
JOIN lp_case_seed c ON c.seed_no=s.seed_no AND BINARY t.input_data=BINARY c.input_data
SET t.expected_output=c.expected_output,t.is_sample=c.is_sample;''',
      '''INSERT INTO test_cases (problem_id,input_data,expected_output,is_sample)
SELECT p.id,c.input_data,c.expected_output,c.is_sample FROM lp_case_seed c
JOIN lp_problem_seed s ON s.seed_no=c.seed_no JOIN problems p ON BINARY p.title=BINARY s.title
WHERE NOT EXISTS (SELECT 1 FROM test_cases t WHERE t.problem_id=p.id AND BINARY t.input_data=BINARY c.input_data);''',
      'COMMIT;',
      '''SELECT p.id,p.title,COUNT(t.id) AS total_cases,SUM(t.is_sample=1) AS public_examples,SUM(t.is_sample=0) AS hidden_cases
FROM problems p JOIN lp_problem_seed s ON BINARY p.title=BINARY s.title LEFT JOIN test_cases t ON t.problem_id=p.id GROUP BY p.id,p.title ORDER BY p.id;''',
      'DROP TEMPORARY TABLE lp_case_seed;', 'DROP TEMPORARY TABLE lp_problem_seed;']
    (ROOT/'sql/01_strengthen_problem_bank.sql').write_text('\n\n'.join(lines)+'\n',encoding='utf-8')
    count=sum(len(p['cases']) for p in BANK)
    catalog=[f'# 러닝패스 문제 은행: {len(BANK)}문제 / {count}개 검증 케이스',
      '기존 문제 25개 보강 + 신규 문제 10개. 각 문제의 앞 두 케이스만 공개 예제입니다.',
      '번호는 관리용 순번이며 기존 DB의 실제 id는 제목으로 매핑하여 보존합니다.',
      '|번호|문제|난이도|유형|전체|공개|비공개|','|---|---|---|---|---:|---:|---:|']
    for p in BANK:catalog.append(f"|{p['seed_no']}|{p['title']}|{p['difficulty']}|{p['category']}|{len(p['cases'])}|2|{len(p['cases'])-2}|")
    catalog+=['','## 명세를 명확하게 한 부분','- 평균: 정수/소수 출력 모두 허용, 절대 또는 상대 오차 10^-6.',
      '- 중복 제거: 오름차순. 가장 긴 단어: 길이가 같으면 먼저 입력된 단어.',
      '- 피보나치 F(0)=0, F(1)=1. 계단 N=0은 1가지.',
      '- 그래프는 무방향, BFS 거리는 간선 수. 도달 불가 -1, 연결 요소는 고립 정점도 포함.',
      '- 동전은 무제한 사용, K=0은 0, 불가능하면 -1.',
      '- 테스트에는 음수/0/최솟값·최댓값/중복/동률/도달 불가/탐욕 반례 등이 포함됩니다.']
    (ROOT/'data/문제은행_목록.md').write_text('\n'.join(catalog)+'\n',encoding='utf-8')
    print(f'Generated {len(BANK)} problems, {count} cases, {len(BANK)*2} public examples, {count-len(BANK)*2} hidden cases')

if __name__=='__main__':build()
