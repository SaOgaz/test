;+
; NAME:
;   coeff2v23
;
; PURPOSE:   (one line only)
;   converts coeffs to v2 v3 coordinate system and creates a mean coeff file.
;
; DESCRIPTION:
;   Converts coefficients from Vera's coeff files into the V2V3 system and 
;   outputs files with this information. It can handle looking at only a single
;   file or will make a mean of all files supplied. 
;   This is just rotating coefficients and calculating the angle that the ccd
;   is off, this runs on individual chips.
;
; CATEGORY:
;   Distortion
; CALLING SEQUENCE:
;   coeff2v23,cdir,ext_search,prefix
;
; INPUTS:
;   cdir       - Directory that contains .coeff files.
;
;   ext_search - The chip extension to search for. Looks for ext_search.coeff
;                in the cdir.
;
;   prefix  - String that contains a unique identifier for the current version 
;             of the IDC table. Usually a date string like '0205'. This will 
;	      be prepended to the front of every file written to make sure 
;	      not to overwrite old files.
;
; OPTIONAL INPUT PARAMETERS:
;   odir    - Directory that everything is written to
;             default : /grp/hst/acs/dborncamp/+(pre_sm04 or post_sm04) based on
;             the post flag.
;
;   angfile - The pav3_angle.stat file created from imcomatch
;             default: odir+prefix+'_pav3_allangle.stat'
;
;  thetafile - The file containing the mean theta to override the calculated 
;              theta value. This is only used if calc_mean is not set. The 
;              default will be to look at f606wtheta.txt in:
;              /grp/hst/acs/dborncamp/+ sm +/f606w/f606wtheta.txt
;              where sm is pre or post
;
;
; KEYWORD INPUT PARAMETERS:
;   write     - If set will write the mcoeff or meancoeff files. Default is to
;               write the file.
;
;   verbose   - if set will print to the screen.
;
;   meanf     - if set will create a mean of all coefficient files. Otherwise it
;               will work each file individually. This will allow a time 
;	       dependence to be seen. Default is set to create.
;
;   calc_theta - calculate a theta value for each coeff file. This should not 
;                change as the chips are set so the default is to use the theta
;		calculated from f606w pre-SM04 data.
;
;   post - Tells if working on pre-SM04 or post-SM04 data. This directs where to
;          look for things. If this is set then it will look for post-SM04 
;          data, otherwise it will look for pre-SM04 data.
;
;   eleven - Tells if working on post 2011 data. The SIAF positions changed in
;             2011 so it is important to get the correct date.if post and 
;             eleven are set, eleven will override post. - DISABLED currently
;
;   do_va - Corrects coefficients for velocity aboration.
;
;   va_linear - Apply vafactor to the linear terms only.
;
;   va_poly - Apply vafactor to the terms using vafactor times the power of 
;             the term.
;
;
; OUTPUTS:
;   Will output a meancoeff.txt file (for meanf) or mcoeff.txt file (for not 
;   meanf). The coefficients are not re-ordered at all, just transformed into
;   the V2V3 system. 
;
; KEYWORD OUTPUT PARAMETERS:
; COMMON BLOCKS:
; SIDE EFFECTS:
; RESTRICTIONS:
;   requires some of Marc Buie's IDL routiens, available at:
;   http://www.boulder.swri.edu/~buie/idl/pro/
;
;   or on central storage: /user/dborncamp/idl/buie/
; PROCEDURE:
; MODIFICATION HISTORY:
;   Dec 22 2013 DMB - Created
;   Jan 27 2014 DMB - Upgraded to program and added several keywords and more
;                functionality.
;   Feb 21 2014 DMB - Reworked the auto routiens and created meanf keyword to 
;                work with non mean data. It is now somewhat automated and 
;                can make some decisions on its own. Much easier to use.
;   Apr 1 2014 DMB - Updated documentation.
;
;   Apr 11 2014 DMB - Added eleven keyword to detect change in the v2v3ref SAIF
;                 files. And fixed bug with returning incorrect theta values
;                 due to rotation of the camera. It should now return good theta
;                 values and the calc_theta keyword should be used all the time.
;   Apr 15 2014 DMB - added thetafile keyword to change mean theta values. 
;                 added various speed improvements.
;   May 6 2014 DMB - fixed various bugs when only found one coeff file. And 
;               added the ability to continue if the numbers of coeff files and
;               number in the ang file do not match. Very useful for looking at
;               a single case for debugging.
;   Feb 23 2015 DMB - added do_va keyword to correct for velocity aboration.
;               and disabled the eleven functionality.
;    May 14 2015 DMB - added va_linear keyword to only apply the vafactor 
;                to the linear terms. Also added va_poly keyword.
;
;-
pro coeff2v23,cdir,ext_search,prefix,write=write,meanf=meanf,$
              verbose=verbose,calc_theta=calc_theta,post=post,odir=odir,$
	          angfile=angfile,eleven=eleven,thetafile=thetafile,$
              do_va=do_va,va_linear=va_linear,va_poly=va_poly
;error check and set/get defaults	    
self='coeff2v23'
if badpar(cdir,7,[0,1],caller=self+' cdir ') then return 
if badpar(ext_search,[1,2,3],0,caller=self+' ext_search ') then return 
if badpar(prefix,7,[0,1],caller=self+' prefix ') then return 
if badpar(write,[0,1,2],0,caller=self+' write ',default=1) then return 
if badpar(meanf,[0,1,2],0,caller=self+' meanf ',default=1) then return 
if badpar(verbose,[0,1,2],0,caller=self+' verbose ',default=0) then return 
if badpar(calc_theta,[0,1,2],0,caller=self+'calc_theta ',default=0) then return 
if badpar(post,[0,1,2],0,caller=self+' post ',default=0) then return 
 if post then sm='post_sm04/' else sm='pre_sm04/'
;if badpar(eleven,[0,1,2],0,caller=self+' eleven ',default=0) then return
; if eleven then begin 
;    ang_default='_11_pav3_allangle.stat' 
;    sm='post_sm04/'
; endif else begin
ang_default='_pav3_allangle.stat'
if not post then sm='pre_sm04/'
; endelse
;use a default directory, get correct filter
 filter=strlowcase(strmid(cdir,strpos(strlowcase(cdir),'/f')+1,5))
if badpar(odir,[0,7],0,caller=self+' odir ',$
   default='/grp/hst/acs/dborncamp/'+sm+filter+'/') then return 
if badpar(angfile,[0,7],0,caller=self+' angfile ',default=$
   odir+prefix+ang_default) then return 

;this fixes the 850lp problem for filter. but odir must be defined...
 dir_split=strsplit(odir,'/')
 filtstart=strpos(odir,'/f')+1
 z=where(dir_split ge filtstart, count)

 if count eq 1 then begin
     filter=strmid(odir,dir_split[z[0]],strlen(odir)-dir_split[z[0]]-1)
 endif else begin
     filter=strmid(odir,dir_split[z[0]],dir_split[z[1]]-dir_split[z[0]]-1)
 endelse

if badpar(thetafile,[0,7],0,caller=self+' thetafile ', default=$
   '/grp/hst/acs/dborncamp/'+sm+filter+'/'+filter+'theta.txt') then return
if badpar(do_va,[0,1,2],0,caller=self+' do_va ',default=0) then return 
if badpar(va_linear,[0,1,2],0,caller=self+' va_linear ',default=0) then return 
if badpar(va_poly,[0,1,2],0,caller=self+' va_poly ',default=0) then return 


if va_linear and do_va then begin
    print,'Cannot apply vafactor both ways'
    return
endif

if va_poly and do_va then begin
    print,'Cannot apply vafactor both ways'
    return
endif

if va_linear and va_poly then begin
    print,'Cannot apply vafactor both ways'
    return
endif

case ext_search of 
   1: chip=strn(2)
   4: chip=strn(1)
   else: begin
      print,'Enter a valid extension to search for'
      return
      end
endcase      

cfiles=file_search(cdir+'*_'+strn(ext_search)+'.coeffs',count=nim);this is index
cfile=strmid(cfiles,17,9,/reverse)

if write and meanf then ofile=odir+prefix+'wfc'+chip+'_meancoeffs'
;not angle.stat the pav3
readcol,angfile,$
   name,ra_t,dec_t,crval1,crval2,ORIENT_h,ORIENT_c,EPS,pav3,pav3corr,vafactor,$
   format='(a,d,d,d,d,d,d,d,d,d,d,d)',count=n_angle,/silent

;match things and check
match,cfile,name,ind1,ind2,count=nmatch

;make sure everything in the angfile has a coeff file
if n_elements(ind2) ne n_angle then begin
   print,'warning'
   print,'the number of matched files does not equal number in angle file. may need to redo imcomatch'
   print,'# in angle file: '+string(n_angle)
   print,'# of coeff files: '+string(n_elements(ind2))
   print,' '
   ans=''
   read,ans,prompt='do you want to continue anyway? (yes): '
   if ans ne 'yes' then return
endif

cfile=cfile[ind1]
cfiles=cfiles[ind1]
name=name[ind2]
ra_t=ra_t[ind2]
dec_t=dec_t[ind2]
crval1=crval1[ind2]
crval2=crval2[ind2]
ORIENT_h=ORIENT_h[ind2]
ORIENT_c=ORIENT_c[ind2]
EPS=EPS[ind2]
pav3=pav3[ind2]
pav3corr=pav3corr[ind2]
vafactor=vafactor[ind2]

order=5
terms = (order+1)*(order+2)/2

if order eq 5 then $
    expon=[1,1,1,2,2,2,3,3,3,3,4,4,4,4,4,5,5,5,5,5,5]
if order eq 4 then $
    expon=[1,1,1,2,2,2,3,3,3,3,4,4,4,4,4]

cx=dblarr(terms,nmatch)
cy=dblarr(terms,nmatch)
cax=dblarr(terms,nmatch)
cay=dblarr(terms,nmatch) 
corx=dblarr(terms,nmatch)
cory=dblarr(terms,nmatch)
x_rms=dblarr(terms,nmatch)
y_rms=dblarr(terms,nmatch)

;polulate arrays to do work with
;account for vafactor
for j=0,nmatch-1 do begin
   readcol,cfiles[j],orx,ax,s_ax,ory,ay,s_ay,x_rmss,y_rmss,ntot,$
      format='(i,d,d,i,d,d,f,f,i)',/silent

   ;these are the coefficients
   ;print,vafactor[j]
   if do_va then begin
      cx[*,j]=ax/vafactor[j]
      cy[*,j]=ay/vafactor[j]
   endif else begin
      cx[*,j]=ax
      cy[*,j]=ay
   endelse

   if va_linear then begin
       for i=0,2 do begin
           cx[i,j]=ax[i]/vafactor[j] ;a1
           cy[i,j]=ay[i]/vafactor[j] ;b1
       endfor
;      cx[1,j]=ax[1]/vafactor[j] ;a2
;      cy[1,j]=ay[1]/vafactor[j] ;b2
;      cx[2,j]=ax[2]/vafactor[j] ;a3
;      cy[2,j]=ay[2]/vafactor[j] ;b3
   endif

   if va_poly then begin
       for i=0,terms-1 do begin
           cx[i,j]=ax[i]/(vafactor[j]^expon[i])
           cy[i,j]=ay[i]/(vafactor[j]^expon[i])
       endfor
   endif

   ;supporting information
   cax[*,j]=s_ax
   cay[*,j]=s_ay
   corx[*,j]=orx
   cory[*,j]=ory  
   x_rms[*,j]=x_rmss
   y_rms[*,j]=y_rmss

;   cx0=[cx[*,j]]
;   cy0=[cy[*,j]]
;   corx0=[corx[*,j]]

endfor

;make arrays for later
max_r=dblarr(terms)
may_r=dblarr(terms)
sax_r=dblarr(terms)
say_r=dblarr(terms)
max_rm=dblarr(terms)
may_rm=dblarr(terms)
sax_rm=dblarr(terms)
say_rm=dblarr(terms)

;;;;
; Calculation of angle for rotation from the catalog
; /grp/hst/acs/verap/DISTORION_new/F606W/catalog/output.47tuc.9Kx9K.fits
; CRVAL1  =     0.5645833492E+01
; CRVAL2  =    -0.7206666565E+02
; RA_TARG =   5.655000000000E+00 
; DEC_TARG=  -7.207055555556E+01
; CRPIX1  =  5000
; CRPIX2  =  5000
;;;;

RA_c =  double( 5.655000000000E+00) ;in degree
DEC_c=  double(-7.207055555556E+01) ;in degree

if calc_theta then begin
   dtor=!dpi/180
   
   D_RA=(RA_t-RA_c)*dtor       ;subtract ra and convert to radian 
   ;should dec be subtracted as well? no, only a shift in ra as there is no
   ;change in x direction for difference in center of chips and center of moasic
   ;assumes chip rotation never changes
   dec_c=(DEC_c)*dtor            ;convert to radians
   epsilon=(atan(tan(D_RA)*sin(DEC_c)))/dtor ;convert to degree
   theta = ((ORIENT_c-EPS)+epsilon-PAV3corr)*dtor ;in rad
   num=n_elements(theta)
   
   ;get things oriented to same axis, things may appear inverted
   ;rotate 180 degree
   for i=0,num-1 do if theta[i] lt 0.0 then theta[i]=theta[i]+(!dpi)
   ;print,theta;/!dtor
   ;another 180 degree, just in case something was close to zero 
   for i=0,num-1 do if theta[i] lt 0.0 then theta[i]=theta[i]+(!dpi)
   ;print,theta;/!dtor
   ; another just in case, if it was over 180 to begin with
   for i=0,num-1 do if theta[i] lt 0.0 then theta[i]=theta[i]+(!dpi)
   
   mtheta=median(theta)
endif else begin
;if not calc_theta then begin 
   print,'overriding calculated theta!!!'
   ;thetafile='/grp/hst/acs/dborncamp/pre_sm04/f606w/f606wtheta.txt'
   print,'using theta value found in: '+thetafile
   a=''
   openr,unit,thetafile,/get_lun
   readf,unit,a
   free_lun,unit
   mtheta=double(strmid(a,strpos(a,'.')-1,strlen(a)))
   print,'used theta is: ',mtheta
;endif   
endelse

;print,'theta before: ',theta/dtor

;for i=0,n_elements(theta)-1 do $
;   if (theta[i]/!dtor lt 150) then begin
;      print,'bad theta for:'
;      print,name[i],' ',d_ra[i],ra_t[i],theta[i]
;   endif

if verbose and calc_theta then print,' theta in degree: ',theta/!dtor
if verbose then print,' mtheta: ',mtheta
if verbose then print,' mtheta in deg: ',mtheta/!dtor


if write then begin
   thetafile=odir+filter+'theta.txt'
   if verbose then print,'Writing '+thetafile
   if exists(thetafile) then file_delete,thetafile
   openw,unit,thetafile,/get_lun
   printf,unit,'Used theta: ',mtheta
   free_lun,unit
endif

if meanf then begin
   if nmatch lt 2 then begin
      print,'less than 2 files, cannot do mean'
      return
   endif
   if write then begin
      ;if eleven then ofile=odir+prefix+'_11_wfc_'+chip+'_meancoeffs' else $
                     ofile=odir+prefix+'_wfc_'+chip+'_meancoeffs'
      openw,ounit,ofile,/get_lun
      print,'opening: '+ofile
   endif   
   for i=0,terms-1 do begin $
      ;Rotation from ACS/WFC detector to V2V3!
      max_r[i] = mean(-cx[i,*]*cos(mtheta) + cy[i,*]*sin(mtheta))
      may_r[i] = mean(cx[i,*]*sin(mtheta) + cy[i,*]*cos(mtheta))
      max_rm[i] = mean(-cx[i,*]*cos(mtheta) + cy[i,*]*sin(mtheta))
      may_rm[i] = mean(cx[i,*]*sin(mtheta) + cy[i,*]*cos(mtheta))
      
      ;get deviations
      sax_r[i] = stddev(cx[i,*]*cos(mtheta) + cy[i,*]*sin(mtheta))
      say_r[i] = stddev(-cx[i,*]*sin(mtheta) + cy[i,*]*cos(mtheta))
      sax_rm[i] = stddev(cx[i,*]*cos(mtheta) + cy[i,*]*sin(mtheta))
      say_rm[i] = stddev(-cx[i,*]*sin(mtheta) + cy[i,*]*cos(mtheta))
      if verbose then print,format='(i3,4E19.5)',i,max_rm[i],sax_rm[i],may_rm[i],say_rm[i]
   
      if write then begin
         printf,ounit,format='(i3,2E19.5,i5,2E19.5)',$
            i,max_rm[i],sax_rm[i],i,may_rm[i],say_rm[i]
      endif
   endfor
   if write then begin
      free_lun,ounit  
      if verbose then print,'Writing: '+ofile
   endif   
endif else begin ;not mean, no averaging
   for j=0,nmatch-1 do begin
      if write then begin
         if not exists(odir+'nomean/') then file_mkdir,odir+'nomean/'
         ofile=odir+'nomean/'+prefix+'_'+name[j]+'_'+chip+'_mcoeffs'
	 if verbose then print,'Writing: '+ofile
	 openw,ounit,ofile,/get_lun
      endif
      if verbose then print,'working on: '+name[j]
      for i=0,terms-1 do begin
	 ;Rotation from ACS/WFC detector to V2V3!
	 ;get coefficients in correct order, no stdev for single points
	 max_r[i] = -cx[i,j]*cos(mtheta) + cy[i,j]*sin(mtheta)
         may_r[i] = cx[i,j]*sin(mtheta) + cy[i,j]*cos(mtheta)
	 if verbose then print,format='(i3,4E19.5)',i,max_r[i],i,may_r[i]
         
         if write then $
            printf,ounit,format='(i3,2E19.5,i5,2E19.5)',$
               i,max_r[i],99.99,i,may_r[i],99.99
      endfor
      if write then free_lun,ounit  
   endfor
endelse
;forprint,max_r,cx,may_r,cy ;debugging line
end
