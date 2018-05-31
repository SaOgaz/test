pro orientprint,filter,post=post
self=' orientprint '
if badpar(filter,7,0,caller=self+' filter ') then return 
if badpar(post,[0,1,2],0,caller=self+' post ',default=0) then return 

if post then begin
   cdir=[$
     '/grp/hst/acs/verap/DISTORION_new/F435W_2009/meta_pix_ref2raw_5th_test3/',$
      '/grp/hst/acs/verap/DISTORION_new/F606W/meta_pix_ref2raw_5th_test2/',$
      '/grp/hst/acs/verap/DISTORION_new/F814W_2009/meta_pix_ref2raw_test3/']
   
   idir=[$
      '/grp/hst/acs/verap/DISTORION_new/F435W_2009/flt/',$
      '/grp/hst/acs/verap/DISTORION_new/F606W/flt/',$
      '/grp/hst/acs/verap/DISTORION_new/F814W_2009/flt/']
   sm='_flc.fits'
endif else begin
   cdir=[$
     '/grp/hst/acs/verap/DISTORION_new/F435W_2007/meta_pix_ref2raw_5th_test3/',$
     '/grp/hst/acs/verap/DISTORION_new/F606W_2007/meta_pix_ref2raw_5th_test7/',$
     '/grp/hst/acs/verap/DISTORION_new/F814W_2007/meta_pix_ref2raw_5th_test4/']
  
  idir=[$
     '/grp/hst/acs/verap/DISTORION_new/F435W_2007/flt/',$
     '/grp/hst/acs/verap/DISTORION_new/F606W_2007/flt/',$
     '/grp/hst/acs/verap/DISTORION_new/F814W_2007/flt/']
  sm='_flt.fits'
endelse

cdir=cdir[where(strmatch(cdir,'*'+filter+'*',/fold_case) eq 1)]
idir=idir[where(strmatch(idir,'*'+filter+'*',/fold_case) eq 1)]

;idir='/grp/hst/acs/47Tuc/'
;idir='/grp/hst/acs/verap/DISTORION_new/F606W/flt/'
;cdir='/grp/hst/acs/verap/DISTORION_new/F606W/meta_pix_ref2raw_5th_test2/'


print,'looking at images in directory: '+idir
;only get files included in the coefficient
cfiles=file_search(cdir+'*_1.coeffs',count=cnim)
ifiles=file_search(idir+'*'+sm,count=infiles)

;match things to make sure the images exist
cfile=strmid(cfiles,17,9,/reverse)
ifile=strmid(ifiles,17,9,/reverse)
match,cfile,ifile,ind1,ind2,count=nim 

cfile=cfile[ind1]
cfiles=cfiles[ind1]
ifile=ifile[ind2]
ifiles=ifiles[ind2]


;files=file_search(idir+'*flc.fits',count=nfiles)
files=idir[0]+strmid(cfiles,17,9,/reverse_offset)+sm

name=strarr(nim)
ra=dblarr(nim)
dec=dblarr(nim)
post1=dblarr(nim)
post2=dblarr(nim)
orient=dblarr(nim)
year=strarr(nim)
exptime=dblarr(nim)

for i=0,nim-1 do begin
   hdr=headfits(files[i],exten=0)
   hdr1=headfits(files[i],exten=1)

   name[i]=sxpar(hdr,'filename')
   ra[i]=sxpar(hdr,'ra_targ')
   dec[i]=sxpar(hdr,'dec_targ')
   post1[i]=sxpar(hdr,'postarg1')
   post2[i]=sxpar(hdr,'postarg2')
   orient[i]=sxpar(hdr1,'ORIENTAT')
;   year[i]='   '+strmid(sxpar(hdr,'date-obs'),0,4)
   year[i]=datesconv(sxpar(hdr,'date-obs'))
   exptime[i]=sxpar(hdr,'EXPTIME')

endfor
ind=sort(year)
print,'name ','ra','dec','post1','post2','orientat','exptime','year',$
   format='(a17,7a16)'
forprint,name[ind],ra[ind],dec[ind],post1[ind],post2[ind],orient[ind],exptime[ind],year[ind]

end
