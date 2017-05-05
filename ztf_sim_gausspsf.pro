pro ztf_sim_gausspsf,outfile,fullwidth,boxwidth,satval

psf=psf_gaussian(npixel=[boxwidth,boxwidth],fwhm=fullwidth,ndimension=2,/normalize)
peak=max(psf)

; make the header and add the basic values
mkhdr,hd,psf
sxaddpar,hd,'FWHM',fullwidth,' input full-width half-max of gauss profile'
sxaddpar,hd,'PROFILE','gauss',' profile type'
sxaddpar,hd,'PEAK',peak,' peak pixel value'

writefits,outfile,psf,hd

end