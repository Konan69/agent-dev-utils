"""resolve.py FILE IDX MODE [TEXTFILE]: MODE ours|theirs|both|text for conflict hunk IDX (0-based)."""
import sys,re
if "--help" in sys.argv:
    print(__doc__)
    sys.exit(0)
f,idx,mode=sys.argv[1],int(sys.argv[2]),sys.argv[3]
lines=open(f).read().split('\n')
out=[];i=0;n=-1
while i<len(lines):
    l=lines[i]
    if l.startswith('<<<<<<< '):
        n+=1
        j=i+1;ours=[]
        while not lines[j].startswith('=======') and not lines[j].startswith('||||||| '): ours.append(lines[j]);j+=1
        if lines[j].startswith('||||||| '):
            while not lines[j].startswith('======='): j+=1
        j+=1;theirs=[]
        while not lines[j].startswith('>>>>>>> '): theirs.append(lines[j]);j+=1
        if n==idx:
            if mode=='ours': out+=ours
            elif mode=='theirs': out+=theirs
            elif mode=='both': out+=ours+theirs
            else: out+=open(sys.argv[4]).read().rstrip('\n').split('\n')
        else:
            out+=lines[i:j+1]
        i=j+1;continue
    out.append(l);i+=1
open(f,'w').write('\n'.join(out))
