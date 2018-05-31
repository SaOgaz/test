;
;a .r script that runs everything for pre-SM04 to be in IDC format
;
;Will need to change:
;        cdir - to point to the directories with the coefficients
;        idir - to point to the directories with the images
;        prefix - this needs to be unique to the run, it will be used for everything,
;                the program is smart enough to search for things matching this prefix
;                so keep it consistant for the run.
;
;dir is ok, but will need to comment out f435 and 814 if only doing f606
;
;directories for coefficients
;cdir=[$
;   '/grp/hst/acs/verap/DISTORION_new/F435W_2007/meta_pix_ref2raw_5th_test3/',$
;   '/grp/hst/acs/verap/DISTORION_new/F606W_2007/meta_pix_ref2raw_5th_test7/',$
;   '/grp/hst/acs/verap/DISTORION_new/F814W_2007/meta_pix_ref2raw_5th_test4/']
;
;;directories for images
;idir=[$
;   '/grp/hst/acs/verap/DISTORION_new/F435W_2007/flt/',$
;   '/grp/hst/acs/47Tuc/',$
;   '/grp/hst/acs/verap/DISTORION_new/F814W_2007/flt/']
;
;directories to write output files


;remember to change the catall_pre.sh and readacspoly for new filters!!!!!

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
dir=['pre_sm04/f606w/',$
     'pre_sm04/f814w/',$
     'pre_sm04/f435w/',$
     'pre_sm04/f775w/',$
     'pre_sm04/f475w/',$
     'pre_sm04/f625w/',$
     'pre_sm04/f658n/',$
     'pre_sm04/f555w/',$
     'pre_sm04/f502n/',$
     'pre_sm04/f850lp/']

prefix='05302018_slh_pre'

post=0
meanf=1


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
   print,'filter found: ' + filter

;   odir = strmid(dir[i],0,strlen(dir[i])-7)
   odir=dir[i]

   print,' *  imcomatch'
   imcomatch,cdir[i],idir[i],prefix,post=post,odir=odir
   
   print,' *   coeff2v23'
   coeff2v23,cdir[i],1,prefix,meanf=meanf,calc_theta=1,post=post,odir=odir
   coeff2v23,cdir[i],4,prefix,meanf=meanf,calc_theta=1,post=post,odir=odir
   
   chip1=file_search(dir[i]+prefix+'*_1_meancoeffs',count=n1)
   chip2=file_search(dir[i]+prefix+'*_2_meancoeffs',count=n2)
   
   if n1 ne n2 then begin
      print,'** Different number of mcoeffs' 
      return
   endif   
   
   if n1 eq 0 then begin
       print,''
       print,' *** No meancoeffs found!! check dir!!'
       print,dir[i]
       print,''
   endif

   print,' *  veraacscoeff'
   for j=0,n1-1 do begin
      veraacscoeff,chip1[j],1,verbose=0
      veraacscoeff,chip2[j],2,verbose=0
   endfor
   
   mtext1=file_search(dir[i]+prefix+'*_1_meancoeffs.txt',count=nt1)
   mtext2=file_search(dir[i]+prefix+'*_2_meancoeffs.txt',count=nt2)
   fcoeff=strmid(mtext1,0,strlen(mtext1[0])-strlen('_1_meancoeffs.txt'))+'_fincoeff.txt'
   idcfile=strmid(mtext1,0,strlen(mtext1[0])-strlen('_1_meancoeffs.txt'))+'_idc.txt'
   
   
   print,' *  merge text file and readacspoly'
   for j=0,nt1-1 do begin
      spawn,'cat '+mtext1[j]+' > '+fcoeff[j]
      spawn,'cat '+mtext2[j]+' >> '+fcoeff[j]
      readacspoly,fcoeff[j],idcfile[j],verbose=0,/pre,acsfilters=filter
   endfor
   print,''
endfor

print,''
print,'** alltimdep'
alltimdep,prefix,'/Users/slhoffmann/acs/geodist/testing/',idir='/grp/hst/acs2/astrometric_ref/47tuc/wfc/',verbose=0,/fit_606,/jay_date;,/show_plot

print,''
print,''
print,'** spawning catall_pre **'
print,'!!!!!Check to make sure it is updated!!'
print,''

spawn,'/Users/slhoffmann/acs/geodist/dave_grit_repo/idc_transforms_master/catall_pre.sh '+prefix

print,''
print,'** spawning idcfcreate'
print,''
;spawn,'/Users/dborncamp/STScI/ssbx_091615/variants/common/bin/python idcfcreate.py '+'/grp/hst/acs/dborncamp/pre_sm04/all/'+prefix+'_all_idc.txt'
;spawn,'/Users/dborncamp/STScI/ssbx_032315/variants/common/bin/python idcfcreate.py '+'/grp/hst/acs/dborncamp/pre_sm04/all/'+prefix+'_all_idc.txt'
spawn,'/Users/slhoffmann/miniconda3/envs/astroconda27/bin/python /Users/slhoffmann/acs/geodist/dave_grit_repo/idc_transforms_master/idcfcreate.py '+'/Users/slhoffmann/acs/geodist/testing/pre_sm04/all/'+prefix+'_all_idc.txt '+prefix

end
