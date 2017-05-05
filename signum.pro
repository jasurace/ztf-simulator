function signum,in

case 1 of
in lt 0: out=-1
in eq 0: out=0
else: out=1
endcase

return,out

end