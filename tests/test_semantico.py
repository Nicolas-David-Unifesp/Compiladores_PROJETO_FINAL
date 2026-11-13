"""Testes de integracao: Flex, Bison, arvore e analise semantica."""
import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
CASES = [
    ("minimo", "void main(void) {}", None),
    ("vetores e chamada", "int primeiro(int v[]) { return v[0]; } void main(void) { int a[2]; int x; a[0]=3; x=primeiro(a); }", None),
    ("recursao", "int f(int n) { if(n==0) return 1; else return n*f(n-1); } void main(void) { int x; x=f(3); }", None),
    ("escopos", "int x; void main(void) { int x; x=1; { int x; x=2; } }", None),
    ("nao declarada", "void main(void) { b=1; }", "nao declarada"),
    ("atribuicao void", "void f(void) {} void main(void) { int a; a=f(); }", "inteiro escalar"),
    ("variavel void", "void a; void main(void) {}", "tipo void"),
    ("duplicidade", "void main(void) { int a; int a; }", "duplicada"),
    ("funcao inexistente", "void main(void) { f(); }", "nao e funcao declarada"),
    ("sem main", "int a;", "void main(void)"),
    ("main incorreta", "int main(void) { return 0; }", "void main(void)"),
    ("conflito funcao", "void f(void) {} void main(void) { int f; }", "conflita com funcao"),
    ("quantidade", "void f(int x) {} void main(void) { f(); }", "espera 1"),
    ("tipo argumento", "void f(int x[]) {} void main(void) { int a; f(a); }", "tipo de argumento"),
    ("retorno ignorado", "int f(void) { return 1; } void main(void) { f(); }", "ignorado"),
    ("parametro duplicado local", "void f(int x) { int x; } void main(void) {}", "duplicada"),
    ("fora de escopo", "void main(void) { { int x; } x=1; }", "nao declarada"),
    ("declaracao posterior", "void main(void) { f(); } void f(void) {}", "nao e funcao declarada"),
    ("indice escalar", "void main(void) { int x; x[0]=1; }", "nao e vetor"),
    ("vetor vazio", "int a[0]; void main(void) {}", "tamanho positivo"),
    ("retorno ausente", "int f(int x) { if(x) return 1; } void main(void) {}", "sem retornar"),
    ("return void com valor", "void main(void) { return 1; }", "nao pode retornar"),
    ("return int vazio", "int f(void) { return; } void main(void) {}", "deve retornar"),
    ("numero grande", "void main(void) { int a; a=999999999999999999999; }", "fora do intervalo"),
    ("erro sintatico", "void main(void) { int ; }", "ERRO SINTATICO"),
    ("erro lexico", "void main(void) { @; }", "ERRO LÉXICO"),
    ("comentario aberto", "void main(void) { /*", "nao foi fechado"),
    ("localizacao", "void main(void) {\n\n x=1;\n}", "linha 3"),
]
with tempfile.TemporaryDirectory() as directory:
    source = pathlib.Path(directory) / "entrada.cm"
    for name, program, diagnostic in CASES:
        source.write_text(program)
        result = subprocess.run([str(ROOT / "build/analisador"), str(source)], capture_output=True, text=True)
        output = result.stdout + result.stderr
        assert result.returncode == (0 if diagnostic is None else 1), (name, output)
        if diagnostic:
            assert diagnostic in output, (name, output)
        assert "ARVORE SINTATICA:" in result.stdout and "TABELA DE SIMBOLOS:" in result.stdout, (name, output)
        assert ("Compilacao com sucesso." in result.stdout) == (diagnostic is None), (name, output)
        print(f"OK: {name}")
    recovery_cases = [
        ("comando invalido", "void main(void) { int x; x=; x=2; }", ["funcao main", "declaracao x", "numero 2", "trecho com erro sintatico", "x\tvariavel"]),
        ("declaracao local invalida", "void main(void) { int ; int x; x=2; }", ["funcao main", "declaracao x", "x\tvariavel"]),
        ("declaracao global invalida", "int ; int x; void main(void) {}", ["declaracao x", "funcao main", "x\tvariavel"]),
        ("fim inesperado", "int x; void main(void) { int y;", ["declaracao x", "x\tvariavel"]),
        ("sem trecho recuperavel", "void main(void) {", ["Nenhuma declaracao completa recuperada"]),
        ("lexico com recuperacao", "void main(void) { int x; x=@2; }", ["funcao main", "numero 2", "x\tvariavel"]),
    ]
    for name, program, expected in recovery_cases:
        source.write_text(program)
        result = subprocess.run([str(ROOT / "build/analisador"), str(source)], capture_output=True, text=True)
        assert result.returncode == 1, (name, result)
        assert "Parcial:" in result.stdout, (name, result.stdout)
        for text in expected:
            assert text in result.stdout, (name, text, result.stdout)
        assert "Compilacao com sucesso." not in result.stdout
        print(f"OK: recuperacao - {name}")
print(f"{len(CASES) + len(recovery_cases)} testes passaram.")
