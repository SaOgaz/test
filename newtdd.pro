preidcfile='/grp/hst/acs/dborncamp/pre_sm04/all/031815_pre_all_yscale_idc.fits'
postidcfile='/grp/hst/acs/dborncamp/post_sm04/all/031815_post_all_yscale_idc.fits'
updatehdr=1

exten=1
;if ((exten ne 1) or (exten ne 4)) then begin
;    print,'select a valid chip'
;    return
;endif


case exten of
    1: chip=2
    4: chip=1
    else: begin
        print,'Please enter a valid extension'
        return
    end
endcase


;if exten eq 1 then chip=2 else chip=1

prefix=['031815_post','031815_pre']

badtxt='badresid.txt'

dir=[$
    '/grp/hst/acs/dborncamp/post_sm04/f435w/nomean/',$
    '/grp/hst/acs/dborncamp/post_sm04/f606w/nomean/',$
    '/grp/hst/acs/dborncamp/post_sm04/f814w/nomean/',$
    '/grp/hst/acs/dborncamp/pre_sm04/f435w/nomean/',$
    '/grp/hst/acs/dborncamp/pre_sm04/f606w/nomean/',$
    '/grp/hst/acs/dborncamp/pre_sm04/f814w/nomean/']

ytitle='arc-sec/pix'

odir=[$
     '/grp/hst/acs/dborncamp/post_sm04/f435w/',$
     '/grp/hst/acs/dborncamp/post_sm04/f606w/',$
     '/grp/hst/acs/dborncamp/post_sm04/f814w/',$
     '/grp/hst/acs/dborncamp/pre_sm04/f435w/',$
     '/grp/hst/acs/dborncamp/pre_sm04/f606w/',$
     '/grp/hst/acs/dborncamp/pre_sm04/f814w/']

idir=['/grp/hst/acs2/astrometric_ref/47tuc/wfc/f606w/',$
      '/grp/hst/acs2/astrometric_ref/47tuc/wfc/f814w/',$
      '/grp/hst/acs2/astrometric_ref/47tuc/wfc/f435w/']

if badpar(prefix,7,0,caller=self+' prefix ') then return 
if badpar(dir,[0,7],0,caller=self+' dir ',default='/grp/hst/acs/dborncamp/') then return 
if badpar(idir,[0,7],0,caller=self+' idir ',default='/grp/hst/acs2/astrometric_ref/47tuc/wfc/*/') then return 
if badpar(updatehdr,[0,1,2],0,caller=self+' updatehdr ',default=1) then return 
if badpar(show_plot,[0,1,2],0,caller=self+' show_plot ',default=0) then return 
if badpar(verbose,[0,1,2],0,caller=self+' verbose ',default=0) then return 
if badpar(fit_606,[0,1,2],0,caller=self+' fit_606 ',default=0) then return
if badpar(jay_date,[0,1,2],0,caller=self+' jay_date ',default=0) then return


;find all of the coeff files
counter=0
files=''
for i=0,n_elements(dir)-1 do begin
    search=dir[i]+prefix[*]+'*_*idc.txt'
    ;exclude not found directories, file search will return empty string on fail
    if counter eq 0 then begin
        temp=file_search(search)
        if temp[0] ne '' then begin
            files=temp
            counter++
        endif
    endif else begin
        files=[files,file_search(search)]
    endelse
endfor

root=strmid(files,16,9,/reverse_offset)

nonuniq=n_elements(root)
root=root[uniq(root)]
files=files[uniq(root)]

counter=0
for i=0,n_elements(idir)-1 do begin
    if counter eq 0 then imfiles=file_search(idir[i]+root+'_fl?.fits') $
        else imfiles=[imfiles,file_search(idir[i]+root+'_fl?.fits')]
    counter++
endfor

imroot=strmid(imfiles,17,9,/reverse_offset)

nonuniqim=n_elements(imroot)
imroot=imroot[uniq(imroot)]
imfiles=imfiles[uniq(imroot)]


;reject bad images from file badresid.txt
for i=0,n_elements(odir)-1 do begin
    badfile=odir[i]+badtxt
    ;print,'badfile: '+badfile
   if exists(badfile) then begin 
      readcol,badfile,bfile,format='a',count=n_bad,/silent
      if n_bad gt 0 then begin
         ;print,'Taking out bad files based on manually checked bad residuals '+odir[i]
         ;forprint,bfile
         match,bfile,root,ind1,ind2
         root[ind2]='999'
      endif
   endif
endfor

;match the image and coeff files
match,root,imroot,ind1,ind2,count=nfiles
files=files[ind1]
root=root[ind1]
imfiles=imfiles[ind2]
imroot=imroot[ind2]
nfiles=n_elements(files)

;get the dates now that everything in the right order
ddate=dblarr(nfiles)
pa_v3=dblarr(nfiles)

for i=0,nfiles-1 do begin
    if imfiles[i] eq '' then continue
    hdr=headfits(imfiles[i],exten=0)
    dateobs=sxpar(hdr,'DATE-OBS')
    ddate[i]=datesconv(dateobs)
    pa_v3[i]=sxpar(hdr,'PA_V3')
endfor

order=5
terms = (order+1)*(order+2)/2

;create arrays for things to live
x_coeff=dblarr(nfiles,terms)
y_coeff=dblarr(nfiles,terms)
x_error=fltarr(nfiles,terms)
y_error=fltarr(nfiles,terms)
x_id=lonarr(nfiles,terms)
y_id=lonarr(nfiles,terms)
filter=strarr(nfiles)

;read in files and populate arrays
for i=0,nfiles-1 do begin  ;files
    if files[i] eq '' then continue
    readcol,files[i],c10,c11,c20,c21,c22,c30,c31,c32,c33,c40,c41,$
        c42,c43,c44,c50,c51,c52,c53,c54,c55,/silent,$
        format='d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d',count=count

    if exten eq 1 then place=2 else place=0

    x_coeff[i,0]=.05
    x_coeff[i,1]=c10[place] 
    x_coeff[i,2]=c11[place]
    x_coeff[i,3]=c20[place]
    x_coeff[i,4]=c21[place]
    x_coeff[i,5]=c22[place]
    x_coeff[i,6]=c30[place]
    x_coeff[i,7]=c31[place]
    x_coeff[i,8]=c32[place]
    x_coeff[i,9]=c33[place]
    x_coeff[i,10]=c40[place]
    x_coeff[i,11]=c41[place]
    x_coeff[i,12]=c42[place]
    x_coeff[i,13]=c43[place]
    x_coeff[i,14]=c44[place]
    x_coeff[i,15]=c50[place]
    x_coeff[i,16]=c51[place]
    x_coeff[i,17]=c52[place]
    x_coeff[i,18]=c53[place]
    x_coeff[i,19]=c54[place]
    x_coeff[i,20]=c55[place]

    y_coeff[i,0]=.05
    y_coeff[i,1]=c10[place+1]
    y_coeff[i,2]=c11[place+1]
    y_coeff[i,3]=c20[place+1]
    y_coeff[i,4]=c21[place+1]
    y_coeff[i,5]=c22[place+1]
    y_coeff[i,6]=c30[place+1]
    y_coeff[i,7]=c31[place+1]
    y_coeff[i,8]=c32[place+1]
    y_coeff[i,9]=c33[place+1]
    y_coeff[i,10]=c40[place+1]
    y_coeff[i,11]=c41[place+1]
    y_coeff[i,12]=c42[place+1]
    y_coeff[i,13]=c43[place+1]
    y_coeff[i,14]=c44[place+1]
    y_coeff[i,15]=c50[place+1]
    y_coeff[i,16]=c51[place+1]
    y_coeff[i,17]=c52[place+1]
    y_coeff[i,18]=c53[place+1]
    y_coeff[i,19]=c54[place+1]
    y_coeff[i,20]=c55[place+1]
    
    filter[i]=strmid(files[i],strpos(strlowcase(files[i]),'/f')+1,5)
endfor

;find the filters
z435p=where(strupcase(filter) eq 'F435W',c435p)
z606p=where(strupcase(filter) eq 'F606W',c606p)
z814p=where(strupcase(filter) eq 'F814W',c814p)

;set ztime
split=2009
preztime=2004.5
postztime=2012.0

;get the index of filters and pre/post things
z435pre=where((ddate lt split) and (strupcase(filter) eq 'F435W'),n435pre)
z435post=where((ddate gt split) and (strupcase(filter) eq 'F435W'),n435post)
z606pre=where((ddate lt split) and (strupcase(filter) eq 'F606W'),n606pre)
z606post=where((ddate gt split) and (strupcase(filter) eq 'F606W'),n606post)
z814pre=where((ddate lt split) and (strupcase(filter) eq 'F814W'),n814pre)
z814post=where((ddate gt split) and (strupcase(filter) eq 'F814W'),n814post)
zpre=where(ddate lt split,npre)
zpost=where(ddate gt split,npost)

;Xc = A1 +A2X +A3Y +A4X2 +A5XY +A6Y2 +A7X3 +...+A21Y5 
;Yc = B1 +B2X + B3Y +B4X2 +B5XY +B6Y2 +B7X3 +...+B21Y5
;
;A2 and B3 are scale
;A3 and B2 are rotation
;A4 and B5 are tilt

;cx_10=x_coeff[*,1] ; xrot
cx_11=x_coeff[*,2] ; xscale

cy_10=y_coeff[*,1] ; yscale
cy_11=y_coeff[*,2] ; yrot


;fit things
;only fit 606
sigma=4
order=1  ;liner =1
prenewyear=ddate[z606pre]-preztime
postnewyear=ddate[z606post]-postztime
;fit cx_10
;cx_10_fit=goodpoly(newyear,cx_10,order,sigma,cx_10fitted,newx,newy)
;cx_10a=cx_10_fit[0]
;cx_10b=cx_10_fit[1]

;fit pre cx_11
cx_11_fit_pre=goodpoly(prenewyear,cx_11[z606pre],order,sigma,cx_11fitted_pre,newx,newy)
cx_11_fit_pre=poly_fit(prenewyear,cx_11[z606pre],1,/double)
cx_11a_pre=cx_11_fit_pre[0]
cx_11b_pre=cx_11_fit_pre[1]

;fit post cx_11
cx_11_fit_post=goodpoly(postnewyear,cx_11[z606post],order,sigma,cx_11fitted_post,newx,newy)
cx_11_fit_post=poly_fit(postnewyear,cx_11[z606post],1,/double)
cx_11a_post=cx_11_fit_post[0]
cx_11b_post=cx_11_fit_post[1]



;fit pre cy_10
cy_10_fit_pre=goodpoly(prenewyear,cy_10[z606pre],order,sigma,cy_10fitted_pre,newx,newy)
cy_10_fit_pre=poly_fit(prenewyear,cy_10[z606pre],1,/double)
cy_10a_pre=cy_10_fit_pre[0]
cy_10b_pre=cy_10_fit_pre[1]

;fit post cy_10
cy_10_fit_post=goodpoly(postnewyear,cy_10[z606post],order,sigma,cy_10fitted_post,newx,newy)
cy_10_fit_post=poly_fit(postnewyear,cy_10[z606post],1,/double)
cy_10a_post=cy_10_fit_post[0]
cy_10b_post=cy_10_fit_post[1]



;fit pre cy_11
cy_11_fit_pre=goodpoly(prenewyear,cy_11[z606pre],order,sigma,cy_11fitted_pre,newx,newy)
cy_11_fit_pre=poly_fit(prenewyear,cy_11[z606pre],1,/double)
cy_11a_pre=cy_11_fit_pre[0]
cy_11b_pre=cy_11_fit_pre[1]

;fit post cy_11
cy_11_fit_post=goodpoly(postnewyear,cy_11[z606post],order,sigma,cy_11fitted_post,newx,newy)
cy_11_fit_post=poly_fit(postnewyear,cy_11[z606post],1,/double)
cy_11a_post=cy_11_fit_post[0]
cy_11b_post=cy_11_fit_post[1]

;do corrections
;get the correct indexs in idctab for each filter
preidc=mrdfits(preidcfile,1)
postidc=mrdfits(postidcfile,1)

prehdr=headfits(preidcfile)
posthdr=headfits(postidcfile)
cx_11_cor = dblarr(nfiles)
cx_11_cor_test=dblarr(nfiles)
xsclb_pre=sxpar(prehdr,'TDD_CXB'+strn(chip))
xsclb_post=sxpar(posthdr,'TDD_CXB'+strn(chip))

idc606_pre=preidc[where(preidc.filter1 eq 'F606W   ' and preidc.detchip eq chip)]
idc606_post=postidc[where(preidc.filter1 eq 'F606W   ' and preidc.detchip eq chip)]

for i=0,nfiles-1 do begin
    if ddate[i] lt 2009 then begin
        case filter[i] of
            'f606w': idc=preidc[where(preidc.filter1 eq 'F606W   ' and preidc.detchip eq chip)]
            'f814w': idc=preidc[where(preidc.filter2 eq 'F814W   ' and preidc.detchip eq chip)]
            'f435w': idc=preidc[where(preidc.filter2 eq 'F435W   ' and preidc.detchip eq chip)]
        endcase
        cx_11_cor[i]=cx_11[i]-(cx_11a_pre+(xsclb_pre*(ddate[i]-preztime)))
        dcx11=idc606_pre.cx11-idc.cx11
        cx_11_cor_test[i]=cx_11[i]-(cx_11a_pre-dcx11+(xsclb_pre*(ddate[i]-preztime)))
        
    endif else begin 
        case filter[i] of
            'f606w': idc=postidc[where(postidc.filter1 eq 'F606W   ' and postidc.detchip eq chip)]
            'f814w': idc=postidc[where(postidc.filter2 eq 'F814W   ' and postidc.detchip eq chip)]
            'f435w': idc=postidc[where(postidc.filter2 eq 'F435W   ' and postidc.detchip eq chip)]
        endcase
        cx_11_cor[i]=cx_11[i]-(cx_11a_post+(xsclb_post*(ddate[i]-postztime)))
        dcx11=idc606_post.cx11-idc.cx11
        cx_11_cor_test[i]=cx_11[i]-(cx_11a_post-dcx11+(xsclb_post*(ddate[i]-postztime)))
    
    endelse
endfor
;;calculate scale in x and y
;cxys=(cx_11 - cy_10)/2D0 ;fit this
;cxys_fit=goodpoly(newyear,cxys,order,sigma,cxys_fitted,newx,newy)
;cxys_a=cxys_fit[0]
;cxys_b=cxys_fit[1]
;
;;calculate rotation terms
;cxyr=(cx_10 + cy_11)/2D0
;cxyr_fit=goodpoly(newyear,cxyr,order,sigma,cxyr_fitted,newx,newy)
;cxyr_a=cxyr_fit[0]
;cxyr_b=cxyr_fit[1]
;
;print,'For extension: '+strn(exten)
;print,'Things needed for scale: '
;print,'  cxys_alpha: ',cxys_a,format='(a,d)'
;print,'  cy_10a: ',cy_10a,format='(a,d)'
;print,'  cy_10b: ',cy_10b,format='(a,d)'
;print,''
;
;print,'Things needed for rotation: '
;print,'  cxyr_alpha: ',cxyr_a,format='(a,d)'
;print,'  cx_10a: ',cx_10a,format='(a,d)'
;print,'  cx_10b: ',cx_10b,format='(a,d)'
;
;see how well the correction did
;cx11_new=(2d0 * cxys_a) + (cy_10a + cy_10b*(ddate-preztime))
;cx11_corrected=cx_11-cx11_new
;
;cy11_new=(2D0 * cxyr_a) - (cx_10a + cx_10b*(ddate-preztime))
;cy11_corrected=cy_11-cy11_new

xmin=2002
xmax=2015.5
;window,0
;plot,ddate,cxys,/nodata,xrange=[xmin,xmax],background='ffffff'xl,$
;    color='000000'xl,title='cxys Exten: '+strn(exten),xmargin=[12,2];,$
;    ;charthick=2,charsize=2
;oplot,ddate[z606p],cxys[z606p],psym=4,color='00ff00'xl,thick=2
;oplot,ddate[z814p],cxys[z814p],psym=4,color='0000ff'xl,thick=2
;oplot,ddate,cxys_fitted,color='000000'xl
;
;window,1
;plot,ddate,cxyr,/nodata,xrange=[xmin,xmax],background='ffffff'xl,$
;    color='000000'xl,title='cxyr  Exten: '+strn(exten),xmargin=[12,2];,$
;    ;charthick=2,charsize=2
;oplot,ddate[z606p],cxyr[z606p],psym=4,color='00ff00'xl,thick=2
;oplot,ddate[z814p],cxyr[z814p],psym=4,color='0000ff'xl,thick=2
;oplot,ddate,cxyr_fitted,color='000000'xl
;
;window,2
;plot,ddate,cx11_corrected,/nodata,xrange=[xmin,xmax],background='ffffff'xl,$
;    color='000000'xl,title='cx11_corrected Exten: '+strn(exten),xmargin=[12,2];,$
;    ;charthick=2,charsize=2
;oplot,ddate[z606p],cx11_corrected[z606p],psym=4,color='00ff00'xl,thick=2
;oplot,ddate[z814p],cx11_corrected[z814p],psym=4,color='0000ff'xl,thick=2
;
;window,3
;plot,ddate,cy11_corrected,/nodata,xrange=[xmin,xmax],background='ffffff'xl,$
;    color='000000'xl,title='cy11_corrected Exten: '+strn(exten),xmargin=[12,2];,$
;    ;charthick=2,charsize=2
;oplot,ddate[z606p],cy11_corrected[z606p],psym=4,color='00ff00'xl,thick=2
;oplot,ddate[z814p],cy11_corrected[z814p],psym=4,color='0000ff'xl,thick=2

window,0
plot,ddate,cx_11,/nodata,xrange=[xmin,xmax],background='ffffff'xl,$
    color='000000'xl,xmargin=[12,2],title='cx_11 - x scale. extension '+strn(exten),xtitle='Year',$
    ytitle='arc-sec/pix',charsize=1.5,charthick=2
oplot,ddate[z606p],cx_11[z606p],psym=4,color='00ff00'xl,thick=2
oplot,ddate[z435p],cx_11[z435p],psym=4,color='ff0000'xl,thick=2
oplot,ddate[z814p],cx_11[z814p],psym=4,color='0000ff'xl,thick=2
oplot,ddate[z606pre],cx_11fitted_pre,color='000000'
oplot,ddate[z606post],cx_11fitted_post,color='000000'

window,1
plot,ddate,cy_10,/nodata,xrange=[xmin,xmax],background='ffffff'xl,$
    color='000000'xl,xmargin=[12,2],title='cy_10 - y scale. extension '+strn(exten),xtitle='Year',$
    ytitle='arc-sec/pix',charsize=1.5,charthick=2
oplot,ddate[z606p],cy_10[z606p],psym=4,color='00ff00'xl,thick=2
oplot,ddate[z435p],cy_10[z435p],psym=4,color='ff0000'xl,thick=2
oplot,ddate[z814p],cy_10[z814p],psym=4,color='0000ff'xl,thick=2
oplot,ddate[z606pre],cy_10fitted_pre,color='000000'
oplot,ddate[z606post],cy_10fitted_post,color='000000'

window,2
plot,ddate,cy_11,/nodata,xrange=[xmin,xmax],background='ffffff'xl,$
    color='000000'xl,xmargin=[12,2],title='cy_11 - y rotation. extension '+strn(exten),xtitle='Year',$
    ytitle='arc-sec/pix',charsize=1.5,charthick=2
oplot,ddate[z606p],cy_11[z606p],psym=4,color='00ff00'xl,thick=2
oplot,ddate[z435p],cy_11[z435p],psym=4,color='ff0000'xl,thick=2
oplot,ddate[z814p],cy_11[z814p],psym=4,color='0000ff'xl,thick=2
oplot,ddate[z606pre],cy_11fitted_pre,color='000000'
oplot,ddate[z606post],cy_11fitted_post,color='000000'

print,'xscale fit (cx_11) TDD_CXB'+strn(chip)+' & TDD_CXA'+strn(chip)+' :'
print,'  cx_11a_pre: ',cx_11a_pre,format='(a,e18.10)'
print,'  cx_11b_pre: ',cx_11b_pre,format='(a,e18.10)'
print,'  cx_11a_post: ',cx_11a_post,format='(a,e18.10)'
print,'  cx_11b_post: ',cx_11b_post,format='(a,e18.10)'
print,''

print,'yscale fit (cy_10) TDD_CYB'+strn(chip)+' & TDD_CYA'+strn(chip)+' :'
print,'  cy_10a_pre: ',cy_10a_pre,format='(a,e18.10)'
print,'  cy_10b_pre: ',cy_10b_pre,format='(a,e18.10)'
print,'  cy_10a_post: ',cy_10a_post,format='(a,e18.10)'
print,'  cy_10b_post: ',cy_10b_post,format='(a,e18.10)'
print,''

print,'yrotation fit (cy_11) TDD_CTB'+strn(chip)+' & TDD_CTA'+strn(chip)+' :'
print,'  cy_11a_pre: ',cy_11a_pre,format='(a,e18.10)'
print,'  cy_11b_pre: ',cy_11b_pre,format='(a,e18.10)'
print,'  cy_11a_post: ',cy_11a_post,format='(a,e18.10)'
print,'  cy_11b_post: ',cy_11b_post,format='(a,e18.10)'
print,''

;plot corrected values



if updatehdr then begin
    print,'Updating header of '+preidcfile

    sxaddpar,prehdr,'TDD_CXA'+strn(chip),cx_11a_pre,'Xscale - cx_11',format='(e20.10)',$
        before='HISTORY'
    sxaddpar,prehdr,'TDD_CXB'+strn(chip),cx_11b_pre,'Xscale - cx_11',format='(e20.10)',$
        before='HISTORY'
    sxaddpar,prehdr,'TDD_CYA'+strn(chip),cy_10a_pre,'Yscale - cy_10',format='(e20.10)',$
        before='HISTORY'
    sxaddpar,prehdr,'TDD_CYB'+strn(chip),cy_10b_pre,'Yscale - cy_10',format='(e20.10)',$
        before='HISTORY'
    sxaddpar,prehdr,'TDD_CTA'+strn(chip),cy_11a_pre,'Yrotation - cy_11',format='(e20.10)',$
        before='HISTORY'
    sxaddpar,prehdr,'TDD_CTB'+strn(chip),cy_11b_pre,'Yrotation - cy_11',format='(e20.10)',$
        before='HISTORY'
    if chip eq 2 then $
        sxaddpar,prehdr,'COMMENT','Coefficients corrected for VAFACTOR before averaging',BEFORE='ORIGIN'

    modfits,preidcfile,0,prehdr

    print,'Updating header of '+postidcfile

    sxaddpar,posthdr,'TDD_CXA'+strn(chip),cx_11a_post,'Xscale - cx_11',format='(e20.10)',$
        before='HISTORY'
    sxaddpar,posthdr,'TDD_CXB'+strn(chip),cx_11b_post,'Xscale - cx_11',format='(e20.10)',$
        before='HISTORY'
;    sxaddpar,posthdr,'TDD_CYA'+strn(chip),cy_10a_post,'Yscale - cy_10',format='(e20.10)',$
;        before='HISTORY'
;    sxaddpar,posthdr,'TDD_CYB'+strn(chip),cy_10b_post,'Yscale - cy_10',format='(e20.10)',$
;        before='HISTORY'
    sxaddpar,posthdr,'TDD_CTA'+strn(chip),cy_11a_post,'Yrotation - cy_11',format='(e20.10)',$
        before='HISTORY'
    sxaddpar,posthdr,'TDD_CTB'+strn(chip),cy_11b_post,'Yrotation - cy_11',format='(e20.10)',$
        before='HISTORY'
    if chip eq 2 then $
        sxaddpar,posthdr,'COMMENT','Coefficients corrected for VAFACTOR before averaging',BEFORE='ORIGIN'

    modfits,postidcfile,0,posthdr

endif

end
