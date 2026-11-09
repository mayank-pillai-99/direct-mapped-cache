"""Make the result plots (pgfplots/TikZ) for the report from the CSV files.
  results/summary.csv        -> report/figures/hit_ratio_plot.tex
  results/latency_sweep.csv  -> report/figures/amat_plot.tex
Uses only the Python standard library.
"""
import csv
import os

ROOT = os.path.join(os.path.dirname(__file__), "..")
FIG = os.path.join(ROOT, "report", "figures")
TRACES = ["sequential", "repeated", "random", "conflict", "mixed"]


def read(name):
    with open(os.path.join(ROOT, "results", name)) as f:
        return list(csv.DictReader(f))


def hit_ratio_plot():
    rows = {r["trace"]: r for r in read("summary.csv")}
    coords = " ".join("(%s,%.2f)" % (t, 100 * float(rows[t]["hit_rate"])) for t in TRACES)
    tex = r"""\begin{tikzpicture}
\begin{axis}[ybar, width=\columnwidth, height=4.6cm, ymin=0, ymax=110,
  ylabel={Read hit ratio (\%%)}, symbolic x coords={%s}, xtick=data,
  x tick label style={font=\scriptsize}, nodes near coords, bar width=14pt,
  every node near coord/.append style={font=\scriptsize}, enlarge x limits=0.15]
\addplot[fill=blue!35] coordinates {%s};
\end{axis}
\end{tikzpicture}
""" % (",".join(TRACES), coords)
    with open(os.path.join(FIG, "hit_ratio_plot.tex"), "w") as f:
        f.write(tex)


def amat_plot():
    rows = read("latency_sweep.csv")
    marks = {"sequential": "*", "repeated": "square*", "random": "triangle*", "conflict": "diamond*"}
    plots = []
    for t in ["sequential", "repeated", "random", "conflict"]:
        pts = " ".join("(%s,%s)" % (r["mem_latency"], r["amat_measured"]) for r in rows if r["trace"] == t)
        plots.append(r"\addplot+[mark=%s] coordinates {%s};" % (marks[t], pts))
        plots.append(r"\addlegendentry{%s}" % t)
    tex = r"""\begin{tikzpicture}
\begin{axis}[width=\columnwidth, height=5cm, xlabel={Main-memory latency (cycles)},
  ylabel={AMAT (cycles)}, xmode=log, ymode=log, log basis x=10,
  xtick={5,10,20,50,100}, xticklabels={5,10,20,50,100},
  legend pos=north west, legend style={font=\scriptsize}, grid=major,
  tick label style={font=\scriptsize}]
%s
\end{axis}
\end{tikzpicture}
""" % "\n".join(plots)
    with open(os.path.join(FIG, "amat_plot.tex"), "w") as f:
        f.write(tex)


if __name__ == "__main__":
    os.makedirs(FIG, exist_ok=True)
    hit_ratio_plot()
    amat_plot()
    print("plots written to", FIG)
