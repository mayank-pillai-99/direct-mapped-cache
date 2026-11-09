"""Turn the demo waveform (results/cache_wave.vcd) into a TikZ timing diagram
for the report (report/figures/waveform.tex). Uses only the Python stdlib.

Run after:  vvp -n results/sim.vvp +trace=traces/demo.txt +name=demo +vcd
"""
import os

ROOT = os.path.join(os.path.dirname(__file__), "..")
VCD = os.path.join(ROOT, "results", "cache_wave.vcd")
OUT = os.path.join(ROOT, "report", "figures", "waveform.tex")

SIGNALS = ["clk", "cpu_req", "cpu_addr", "state", "hit_flag", "mem_req",
           "mem_ready", "cpu_ready", "cpu_rdata"]
BUS = {"cpu_addr", "state", "cpu_rdata"}
STATE_NAMES = {0: "IDLE", 1: "CMP", 2: "ALLOC", 3: "WMEM"}
T_START, T_END = 30, 380        # ns window (demo accesses 1-3 and start of 4)
SCALE = 0.042                   # cm per ns


def parse_vcd(path):
    ids, values, scope = {}, {}, []
    with open(path) as f:
        lines = f.read().split("\n")
    i, t = 0, 0
    while i < len(lines):
        tok = lines[i].split()
        i += 1
        if not tok:
            continue
        if tok[0] == "$scope":
            scope.append(tok[2])
        elif tok[0] == "$upscope":
            scope.pop()
        elif tok[0] == "$var" and scope == ["tb_cache"]:
            ids.setdefault(tok[3], tok[4])
        elif tok[0].startswith("#"):
            t = int(tok[0][1:]) // 1000          # ps -> ns
        elif tok[0][0] in "01xz" and len(tok) == 1 and tok[0][1:] in ids:
            values.setdefault(ids[tok[0][1:]], []).append((t, tok[0][0]))
        elif tok[0][0] == "b" and len(tok) == 2 and tok[1] in ids:
            values.setdefault(ids[tok[1]], []).append((t, tok[0][1:]))
    return values


def value_at(changes, t):
    v = "x"
    for ct, cv in changes:
        if ct <= t:
            v = cv
        else:
            break
    return v


def main():
    vals = parse_vcd(VCD)
    # a single "hit" line: high when the comparator reports a hit in COMPARE
    vals["hit_flag"] = vals["stat_hit"]
    out = ["\\begin{tikzpicture}[x=%.3fcm,y=0.42cm,font=\\scriptsize]" % SCALE]
    labels = {"clk": "clk", "cpu_req": "cpu\\_req", "cpu_addr": "cpu\\_addr",
              "state": "state", "hit_flag": "stat\\_hit", "mem_req": "mem\\_req",
              "mem_ready": "mem\\_ready", "cpu_ready": "cpu\\_ready",
              "cpu_rdata": "cpu\\_rdata"}
    for row, name in enumerate(SIGNALS):
        y = -row * 1.6
        out.append("\\node[anchor=east] at (%d,%.2f) {%s};" % (T_START - 3, y + 0.5, labels[name]))
        ch = vals[name]
        times = sorted({T_START, T_END} | {t for t, _ in ch if T_START < t < T_END})
        for a, b in zip(times[:-1], times[1:]):
            v = value_at(ch, a)
            if name in BUS:
                try:
                    n = int(v, 2)
                except ValueError:
                    n = None
                if name == "state":
                    txt = STATE_NAMES.get(n, "x")
                elif n is None:
                    txt = "x"
                else:
                    txt = "%X" % n
                out.append("\\draw (%d,%.2f) -- (%d,%.2f) (%d,%.2f) -- (%d,%.2f);"
                           % (a, y, b, y, a, y + 1, b, y + 1))
                out.append("\\draw (%d,%.2f) -- (%d,%.2f);" % (a, y, a, y + 1))
                if b - a < 18 and name == "state":
                    txt = txt[0]            # short segment: I / C / A / W
                if b - a >= 8:
                    out.append("\\node at (%.1f,%.2f) {\\tiny %s};" % ((a + b) / 2, y + 0.5, txt))
            else:
                lvl = 1 if v == "1" else 0
                out.append("\\draw (%d,%.2f) -- (%d,%.2f);" % (a, y + lvl, b, y + lvl))
                nv = value_at(ch, b)
                if b < T_END and nv != v:
                    out.append("\\draw (%d,%.2f) -- (%d,%.2f);" % (b, y, b, y + 1))
    # access markers
    bottom = -len(SIGNALS) * 1.6 + 0.6
    for t, txt in [(40, "R 0x000: MISS (14 cycles)"), (180, "R 0x004: HIT"), (200, "R 0x00C: HIT"), (220, "R 0x010: MISS ...")]:
        out.append("\\draw[dashed,gray] (%d,1.4) -- (%d,%.2f);" % (t, t, bottom))
        out.append("\\node[anchor=north west,gray!40!black,rotate=0] at (%d,%.2f) {\\tiny %s};"
                   % (t, bottom - (0.6 if t in (200,) else 0), txt))
    out.append("\\end{tikzpicture}")
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w") as f:
        f.write("\n".join(out) + "\n")
    print("wrote", OUT)


if __name__ == "__main__":
    main()
