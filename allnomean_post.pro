;cdir=[$
;   '/grp/hst/acs/verap/DISTORION_new/F435W_2009/meta_pix_ref2raw_5th_test3/',$
;   '/grp/hst/acs/verap/DISTORION_new/F606W/meta_pix_ref2raw_5th_test2/',$
;   '/grp/hst/acs/verap/DISTORION_new/F814W_2009/meta_pix_ref2raw_test3/']
;
;idir=[$
;   '/grp/hst/acs/verap/DISTORION_new/F435W_2009/flt/',$
;   '/grp/hst/acs/verap/DISTORION_new/F606W/flt/',$
;   '/grp/hst/acs/verap/DISTORION_new/F814W_2009/flt/']
;dir=[$
;   'post_sm04/f435w/nomean/',$
;   'post_sm04/f606w/nomean/',$
;   'post_sm04/f814w/nomean/']
;
;
; 606 needs to be first!
;
cdir=['/grp/hst/acs3/verap/DISTORTION/F606W_2009/meta_pix.v22/',$
      '/grp/hst/acs3/verap/DISTORTION/F814W_2009/meta_pix.v2/',$
      '/grp/hst/acs3/verap/DISTORTION/F435W_2009/meta_pix.v2/',$
      '/grp/hst/acs3/verap/DISTORTION/F775W_2009_newcorr/meta_pix.v2/',$
      '/grp/hst/acs3/verap/DISTORTION/F475W_2009/meta_pix.v2/',$
      '/grp/hst/acs3/verap/DISTORTION/F625W_2009/meta_pix.v22/',$
      '/grp/hst/acs3/verap/DISTORTION/F658N_2009/meta_pix.v2/',$
      '/grp/hst/acs3/verap/DISTORTION/F555W_2009/meta_pix.v2/',$
      '/grp/hst/acs3/verap/DISTORTION/F502N_2009/meta_pix.v2/',$
      '/grp/hst/acs3/verap/DISTORTION/F850P_2009/meta_pix.v2/']

idir=['/grp/hst/acs2/astrometric_ref/47tuc/wfc/f606w/',$
      '/grp/hst/acs2/astrometric_ref/47tuc/wfc/f814w/',$
      '/grp/hst/acs2/astrometric_ref/47tuc/wfc/f435w/',$
      '/grp/hst/acs2/astrometric_ref/47tuc/wfc/f775w/',$
      '/grp/hst/acs2/astrometric_ref/47tuc/wfc/f475w/',$
      '/grp/hst/acs2/astrometric_ref/47tuc/wfc/f625w/',$
      '/grp/hst/acs2/astrometric_ref/47tuc/wfc/f658n/',$
      '/grp/hst/acs2/astrometric_ref/47tuc/wfc/f555w/',$
      '/grp/hst/acs2/astrometric_ref/47tuc/wfc/f502n/',$
      '/grp/hst/acs2/astrometric_ref/47tuc/wfc/f850lp/']

dir=['post_sm04/f606w/nomean/',$
     'post_sm04/f814w/nomean/',$
     'post_sm04/f435w/nomean/',$
     'post_sm04/f775w/nomean/',$
     'post_sm04/f475w/nomean/',$
     'post_sm04/f625w/nomean/',$
     'post_sm04/f658n/nomean/',$
     'post_sm04/f555w/nomean/',$
     'post_sm04/f502n/nomean/',$
     'post_sm04/f850lp/nomean/']

;notes for the output file
notes='New coefficients for F775W. SLH trial run.'


prefix='110917_slh_post'

post=1
meanf=0
va_linear=1
va_poly=0
do_va=0
notesfile='post_sm04/all/'+prefix+'_notes.txt'

;make a notes file
openw,ounit,notesfile,/get_lun
printf,ounit,'Notes file for prefix: '+prefix
printf,ounit,'Created on: '+systime()
printf,ounit,'using the following parameters:'
printf,ounit,'post='+strn(post)
printf,ounit,'va_linear='+strn(va_linear)
printf,ounit,'va_poly='+strn(va_poly)
printf,ounit,'do_va='+strn(do_va)
printf,ounit,''
printf,ounit,'using the following inputs:'
printf,ounit,'cdir:'
printf,ounit,cdir
printf,ounit,''
printf,ounit,'idir:'
printf,ounit,idir
printf,ounit,''
printf,ounit,'dir:'
printf,ounit,dir
printf,ounit,''
printf,ounit,notes

free_lun,ounit

for i=0,n_elements(cdir)-1 do begin
   dir_split=strsplit(dir[i],'/')
   filtstart=strpos(dir[i],'/f')+1
   z=where(dir_split ge filtstart, count)

   if count eq 1 then begin
       filter=strmid(dir[i],dir_split[z[0]],strlen(dir[i])-dir_split[z[0]]-1)
   endif else begin
       filter=strmid(dir[i],dir_split[z[0]],dir_split[z[1]]-dir_split[z[0]]-1)
   endelse
   filter=strupcase(filter)

   odir = strmid(dir[i],0,strlen(dir[i])-7)
   ;residlook,cdir[i],/write,post=post
   print,' *  imcomatch'
   imcomatch,cdir[i],idir[i],prefix,post=post,odir=odir
   
   print,' *  coeff2v23'
   coeff2v23,cdir[i],1,prefix,meanf=meanf,calc_theta=1,post=post,$
       va_linear=va_linear,va_poly=va_poly,do_va=do_va,odir=odir
   coeff2v23,cdir[i],4,prefix,meanf=meanf,calc_theta=1,post=post,$
       va_linear=va_linear,va_poly=va_poly,do_va=do_va,odir=odir
   
   chip1=file_search(dir[i]+prefix+'*_1_mcoeffs',count=n1)
   chip2=file_search(dir[i]+prefix+'*_2_mcoeffs',count=n2)
   
   if n1 ne n2 then begin
      print,'** Different number of mcoeffs' 
      return
   endif   

   if n1 eq 0 then begin
       print,''
       print,' *** No .mcoeffs found!! check dir!!'
       print,dir[i]
       print,''
   endif   

   print,' *  veraacscoeff'
   for j=0,n1-1 do begin
      veraacscoeff,chip1[j],1,verbose=0
      veraacscoeff,chip2[j],2,verbose=0
   endfor
   
   mtext1=file_search(dir[i]+prefix+'*_1_mcoeffs.txt',count=nt1)
   mtext2=file_search(dir[i]+prefix+'*_2_mcoeffs.txt',count=nt2)

   filename=strmid(mtext1,strpos(mtext1[0],'_1_mcoeffs')-9,9)

   fcoeff=dir[i]+prefix+'_'+filename+'_fincoeff.txt'
   idcfile=dir[i]+prefix+'_'+filename+'_idc.txt'

   ;fcoeff=strmid(mtext1,0,strlen(mtext1[0])-strlen('_1_mcoeffs.txt'))+'_fincoeff.txt'
   ;idcfile=strmid(mtext1,0,strlen(mtext1[0])-strlen('_1_mcoeffs.txt'))+'_idc.txt'
   
   
   print,' *  merge text file and readacspoly'
   for j=0,nt1-1 do begin
      spawn,'cat '+mtext1[j]+' > '+fcoeff[j]
      spawn,'cat '+mtext2[j]+' >> '+fcoeff[j]
      hdr=headfits(idir[i]+filename[j]+'_flc.fits',exten=0)
      ddate=datesconv(sxpar(hdr,'DATE-OBS'))

      pre_date=2009.   ;the pre change (happened at sm04)
;      post_date=2011.4777  ;the post change (happened when FGS was recalibrated)
      if ddate lt pre_date then print,'!!!! this is not post, retry. ',ddate
;      if (ddate gt pre_date) and (ddate lt post_date) then $
      readacspoly,fcoeff[j],idcfile[j],verbose=0,post=post,pre=0,acsfilters=filter
;      if ddate gt post_date then $
;         readacspoly,fcoeff[j],idcfile[j],verbose=0,/eleven

   endfor
endfor

end
