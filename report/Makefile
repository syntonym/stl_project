all:    pdfl

clean:
	rm -f *aux *bbl *blg *log *out
	
pdfl:
	pdflatex techreport.tex
	bibtex techreport
	pdflatex techreport.tex
	pdflatex techreport.tex
