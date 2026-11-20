# Genera los efectos de sonido de Zombivors por síntesis (sin descargar nada).
# Uso, desde la raíz del repo:  python sonidos/generar_sonidos.py
# Son nuestros: no hay licencia de terceros que citar.
import math, random, struct, wave, os

TASA = 22050
CARPETA = os.path.dirname(os.path.abspath(__file__))
random.seed(10)

def guardar(nombre, muestras):
    pico = max(1e-6, max(abs(m) for m in muestras))
    with wave.open(os.path.join(CARPETA, nombre + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(TASA)
        w.writeframes(b"".join(struct.pack("<h", int(m / pico * 0.85 * 32767)) for m in muestras))

def n(seg): return int(seg * TASA)
def ruido(): return random.uniform(-1, 1)

def paso_bajo(muestras, corte):
    # Filtro de un polo: corte puede ser un número o una función del índice.
    salida, y = [], 0.0
    for i, x in enumerate(muestras):
        c = corte(i) if callable(corte) else corte
        a = 1 - math.exp(-2 * math.pi * c / TASA)
        y += a * (x - y)
        salida.append(y)
    return salida

def golpe():
    m, fase = [], 0.0
    for i in range(n(0.2)):
        t = i / TASA
        fase += 2 * math.pi * (90 - 200 * t) / TASA
        m.append((math.sin(fase) + 0.5 * ruido() * math.exp(-t * 60)) * math.exp(-t * 18))
    return m

def mordisco():
    base = [ruido() for _ in range(n(0.38))]
    sobre = []
    for i in range(len(base)):
        t = i / TASA
        sobre.append(sum(math.exp(-max(0, t - c) * 40) * (t >= c) for c in (0.0, 0.11, 0.22)))
    return [x * e for x, e in zip(paso_bajo(base, 2500), sobre)]

def comer():
    base = paso_bajo([ruido() for _ in range(n(0.45))], 900)
    m = []
    for i, x in enumerate(base):
        t = i / TASA
        m.append((x + 0.3 * math.sin(2 * math.pi * 140 * t)) * (0.5 + 0.5 * math.sin(2 * math.pi * 11 * t)) * math.exp(-t * 5))
    return m

def alerta():
    m = []
    for i in range(n(0.36)):
        t = i / TASA
        f = 660 if t < 0.15 else 880
        cuadrada = 1.0 if math.sin(2 * math.pi * f * t) > 0 else -1.0
        m.append(0.6 * cuadrada * math.exp(-((t % 0.18)) * 9))
    return paso_bajo(m, 3000)

def salida():
    m = []
    for i in range(n(0.7)):
        t = i / TASA
        v = 0.0
        for k, f in enumerate((523.25, 659.25, 783.99)):
            inicio = k * 0.12
            if t >= inicio:
                v += math.sin(2 * math.pi * f * t) * math.exp(-(t - inicio) * 5)
        m.append(v)
    return m

def disparo():
    m, fase = [], 0.0
    for i in range(n(0.22)):
        t = i / TASA
        fase += 2 * math.pi * (900 - 2800 * t) / TASA
        cuadrada = 1.0 if math.sin(fase) > 0 else -1.0
        m.append((0.5 * cuadrada + 0.5 * ruido()) * math.exp(-t * 16))
    return paso_bajo(m, 3500)

def trampa():
    m = []
    for i in range(n(0.5)):
        t = i / TASA
        v = sum(a * math.sin(2 * math.pi * f * t) * math.exp(-t * d) for f, a, d in ((520, 1, 7), (1230, 0.6, 10), (1870, 0.4, 14)))
        m.append(v + ruido() * math.exp(-t * 120))
    return m

def embestida():
    base = [ruido() for _ in range(n(0.32))]
    total = len(base)
    filtrado = paso_bajo(base, lambda i: 300 + 2500 * math.sin(math.pi * i / total))
    return [x * math.sin(math.pi * i / total) for i, x in enumerate(filtrado)]

for nombre, f in (("golpe", golpe), ("mordisco", mordisco), ("comer", comer), ("alerta", alerta),
                  ("salida", salida), ("disparo", disparo), ("trampa", trampa), ("embestida", embestida)):
    guardar(nombre, f())
    print("sonidos/" + nombre + ".wav")
