;cdir=[$
;   '/grp/hst/acs/verap/DISTORION_new/F435W_2007/meta_pix_ref2raw_5th_test3/',$
;   '/grp/hst/acs/verap/DISTORION_new/F606W_2007/meta_pix_ref2raw_5th_test7/',$
;   '/grp/hst/acs/verap/DISTORION_new/F814W_2007/meta_pix_ref2raw_5th_test4/']
;
;idir=[$
;   '/grp/hst/acs/verap/DISTORION_new/F435W_2007/flt/',$
;   '/grp/hst/acs/47Tuc/',$
;   '/grp/hst/acs/verap/DISTORION_new/F814W_2007/flt/']
;
;dir=[$
;   'pre_sm04/f435w/nomean/',$
;   'pre_sm04/f606w/nomean/',$
;   'pre_sm04/f814w/nomean/']
;
;prefix='041114_pre'


; coefficient directory
cdir=['/grp/hst/acs3/verap/DISTORTION/F606W_2002/meta_pix.v5/',$
      '/grp/hst/acs3/verap/DISTORTION/F814W_2002/meta_pix.v3/',$
      '/grp/hst/acs3/verap/DISTORTION/F435W_2002/meta_pix.v3/',$
      '/grp/hst/acs3/verap/DISTORTION/F775W_2002_newcorr/meta_pix.v3/',$
      '/grp/hst/acs3/verap/DISTORTION/F475W_2002/meta_pix.v3/',$
      '/grp/hst/acs3/verap/DISTORTION/F625W_2002/meta_pix.v3/',$
      '/grp/hst/acs3/verap/DISTORTION/F658N_2002/meta_pix.v3/',$
      '/grp/hst/acs3/verap/DISTORTION/F555W_2002/meta_pix.v3/',$
      '/grp/hst/acs3/verap/DISTORTION/F502N_2002/meta_pix.v3/',$
      '/grp/hst/acs3/verap/DISTORTION/F850P_2002/meta_pix.v3/']

; Image directories, need to be in same order as coefficients  
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

; output directory  
dir=['pre_sm04/f606w/nomean/',$
     'pre_sm04/f814w/nomean/',$
     'pre_sm04/f435w/nomean/',$
     'pre_sm04/f775w/nomean/',$
     'pre_sm04/f475w/nomean/',$
     'pre_sm04/f625w/nomean/',$
     'pre_sm04/f658n/nomean/',$
     'pre_sm04/f555w/nomean/',$
     'pre_sm04/f502n/nomean/',$
     'pre_sm04/f850lp/nomean/']

 
;notes for the output file
notes='Same coefficients from Nov 2017. SLH trial run for ACS Hack Day in May 2018.'


;prefix='020216_pre'
prefix='053018_slh_pre'
post=0
meanf=0
va_linear=0
va_poly=0
do_va=1
notesfile='pre_sm04/all/'+prefix+'_notes.txt'

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
      print,'' 
      print,'** Different number of mcoeffs!!' 
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
   fcoeff=strmid(mtext1,0,strlen(mtext1[0])-strlen('_1_mcoeffs.txt'))+'_fincoeff.txt'
   idcfile=strmid(mtext1,0,strlen(mtext1[0])-strlen('_1_mcoeffs.txt'))+'_idc.txt'
   ;help,nt1,nt2
   
   print,' *  merge text file and readacspoly'
   for j=0,nt1-1 do begin
      spawn,'cat '+mtext1[j]+' > '+fcoeff[j]
      spawn,'cat '+mtext2[j]+' >> '+fcoeff[j]
      readacspoly,fcoeff[j],idcfile[j],verbose=0,post=post,pre=1,acsfilters=filter
   endfor

   print,''
endfor
end
