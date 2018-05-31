
idir=[$
     '/grp/hst/acs2/astrometric_ref/47tuc/wfc/f606w/'];,$
;     '/grp/hst/acs2/astrometric_ref/47tuc/wfc/f814w/',$
;     '/grp/hst/acs2/astrometric_ref/47tuc/wfc/f435w/']


dir=[$
;      '/grp/hst/acs/dborncamp/post_sm04/f435w/nomean/',$
      '/grp/hst/acs/dborncamp/post_sm04/f606w/nomean/',$
;      '/grp/hst/acs/dborncamp/post_sm04/f814w/nomean/',$
;      '/grp/hst/acs/dborncamp/pre_sm04/f435w/nomean/',$
      '/grp/hst/acs/dborncamp/pre_sm04/f606w/nomean/'];,$
;      '/grp/hst/acs/dborncamp/pre_sm04/f814w/nomean/']

odir=[$
;      '/grp/hst/acs/dborncamp/post_sm04/f435w/',$
      '/grp/hst/acs/dborncamp/post_sm04/f606w/',$
;      '/grp/hst/acs/dborncamp/post_sm04/f814w/',$
;      '/grp/hst/acs/dborncamp/pre_sm04/f435w/',$
      '/grp/hst/acs/dborncamp/pre_sm04/f606w/'];,$
;      '/grp/hst/acs/dborncamp/pre_sm04/f814w/']

prefix=['021915_pre','022015_post']
exten=1
jay_date=1
badtxt='badresid.txt'
idc=1

;idcfiles=file_search(dir+prefix+'*_idc.txt')

;idcroot=strmid(idcfiles,16,9,/reverse_offset)

;counter=0
;for i=0,n_elements(idir)-1 do begin
;    idcsearch=dir[i]+prefix[*]+'*_*idc.txt'
;    imgsearch=idir[i]+root+'_flc.fits'
;    sptsearch=idir[i]+'spt/'+root+'_spt.fits'
;    if counter eq 0 then begin
;        imgtemp=file_search(imgsearch)
;        spttemp=file_search(sptsearch)
;        idctemp=file_search(idcsearch)
;        if idctemp[0] ne '' then begin
;            idcfiles=idctemp
;            counter++
;        endif
;        if spttemp[0] ne '' then sptfiles=spttemp
;        if imgtemp[0] ne '' then imgfiles=imgtemp
;    endif else begin
;        idcfiles=[idcfiles,file_search(idcsearch)]
;        imgfiles=[imgfiles,file_search(imgsearch)]
;        sptfiles=[sptfiles,file_search(sptsearch)]
;    endelse
;endfor

counter=0
files=''
for i=0,n_elements(dir)-1 do begin
    if idc then $
        search=dir[i]+prefix[*]+'*_*idc.txt' $
    else search=dir[i]+'*_'+strn(exten)+'.coeffs'
    ;exclude not found directories, file search will return empty string on fail
    if counter eq 0 then begin
        temp=file_search(search)
        if temp[0] ne '' then begin
            idcfiles=temp
            counter++
        endif
    endif else begin
        idcfiles=[idcfiles,file_search(search)]
    endelse
endfor

root=strmid(idcfiles,16,9,/reverse_offset)
nonuniq=n_elements(root)
root=root[uniq(root)]
idcfiles=idcfiles[uniq(root)]

counter=0
for i=0,n_elements(idir)-1 do begin
    if counter eq 0 then begin
        imfiles=file_search(idir[i]+root+'_fl?.fits')
        ;sptfiles=file_search(idir[i]+root+'_spt.fits')
    endif else begin
        imfiles=[imfiles,file_search(idir[i]+root+'_fl?.fits')]
        ;sptfiles=[sptfiles,file_search(idir[i]+root+'_spt.fits')]
    endelse
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
      readcol,badfile,bfile,format='a',count=n_bad
      if n_bad gt 0 then begin
         print,'Taking out bad files based on manually checked bad residuals '+odir[i]
         forprint,bfile
         match,bfile,root,ind1,ind2
         root[ind2]='999'
      endif
   endif
endfor

;match the image and coeff files
match,root,imroot,ind1,ind2,count=numfiles
idcfiles=idcfiles[ind1]
root=root[ind1]
imfiles=imfiles[ind2]
;imroot=imroot[uniq(ind2)]
;nfiles=n_elements(files)


;numfiles=n_elements(idcfiles)
cx_10=dblarr(numfiles)
cx_11=dblarr(numfiles)
cy_10=dblarr(numfiles)
cy_11=dblarr(numfiles)
pa_v3=dblarr(numfiles)
dateobs=strarr(numfiles)
temper=fltarr(numfiles)

if exten eq 1 then place=2 else place=0

for i=0,numfiles-1 do begin
    readcol,idcfiles[i],c10,c11,c20,c21,c22,c30,c31,c32,c33,c40,c41,$
        c42,c43,c44,c50,c51,c52,c53,c54,c55,/silent,$
        format='d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d',count=count

    hdr=headfits(imfiles[i])
    ;spthdr=headfits(sptfiles[i], exten=1)

    cx_10[i]=c10[place]
    cx_11[i]=c11[place]
    cy_10[i]=c10[place+1]
    cy_11[i]=c11[place+1]

    pa_v3[i]=sxpar(hdr,'PA_V3')
    dateobs[i]=sxpar(hdr,'DATE-OBS')

    ;temp=sxpar(spthdr,'JWDETMP1')

    ;if temp gt 0 then temp=sxpar(spthdr,'JWDETMP2')
    
    ;temper[i]=temp

endfor

if jay_date then begin
    print,'Overriding ddate with Jays date solutions'
    dateobs=dblarr(n_elements(dateobs))
    imgdir='/grp/hst/acs2/astrometric_ref/47tuc/wfc/'
    filts='f606w'
    for i=0,n_elements(filts)-1 do begin
        readcol,imgdir+filts+'/readheader.out',rootname,pid,date_obs,$
            time_obs,ra,dec,pav3,fil,expt,rdate,vafactor,dra,ddec,d,d,d,$
            format='a,l,a,a,a,a,f,a,i,d,d,f,f,a,a,a',/silent

        rdate=rdate+2000
        match,root,rootname,ind1,ind2
        dateobs[ind1]=rdate[ind2]
    endfor
    fmt='(a10,4d16.12,d12.6,f11.5)'
    comment='#img    cx_10     cx_11    cy_10    cy_11    jay_date    pa_v3'
    forprint,root,cx_10,cx_11,cy_10,cy_11,dateobs,pa_v3,comment=comment,$
    textout='vera_table'+strn(exten)+'.txt',width=200,format=fmt

endif else begin
    fmt='(a10,4d16.12,a12,f12.5)'
    comment='#img    cx_10     cx_11    cy_10    cy_11    date_obs    pa_v3'
    forprint,root,cx_10,cx_11,cy_10,cy_11,dateobs,pa_v3,comment=comment,$
        textout='vera_table'+strn(exten)+'.txt',width=200,format=fmt
endelse
end
