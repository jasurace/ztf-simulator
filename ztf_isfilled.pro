; function check the density of stars on the ccd model
;    by shrinking it and checking to see if any cells are empty
;
;  returns 0 if any part of the image is devoid of stars, 1 otherwise
;
function ztf_isfilled,img

sz=size(img)

newx=floor(sz[1]/1000.)
newy=floor(sz[2]/1000.)

test=rebin(img[0:newx*1000.-1,0:newy*1000.-1],newx,newy)

if (min(test) eq 0) then return,0 else return,1

end