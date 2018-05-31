
pro alltimdep,prefix,dir,idir=idir,post=post,write=write,show_plot=show_plot,$
    verbose=verbose,fit_606=fit_606,jay_date=jay_date,exp_time=exp_time,$
    do_va=do_va
self=' alltimdep ' 

;set defaults and error check
if badpar(prefix,7,0,caller=self+' prefix ') then return 
if badpar(dir,[0,7],0,caller=self+' dir ',default='/grp/hst/acs/dborncamp/') then return 
if badpar(idir,[0,7],0,caller=self+' idir ',default='/grp/hst/acs2/astrometric_ref/47tuc/wfc/*/') then return 
if badpar(post,[0,1,2],0,caller=self+' post ',default=0) then return
if badpar(write,[0,1,2],0,caller=self+' write ',default=1) then return 
if badpar(show_plot,[0,1,2],0,caller=self+' show_plot ',default=0) then return 
if badpar(verbose,[0,1,2],0,caller=self+' verbose ',default=0) then return 
if badpar(fit_606,[0,1,2],0,caller=self+' fit_606 ',default=0) then return
if badpar(jay_date,[0,1,2],0,caller=self+' jay_date ',default=0) then return
if badpar(exp_time,[0,1,2],0,caller=self+' exp_time ',default=0) then return
if badpar(do_va,[0,1,2],0,caller=self+' do_va ',default=0) then return 

print,'Make sure to run nomean first to get the individual coefficients.'

;post=1
;write=0
fitsext='_fl*.fits'
if post eq 1 then begin 
   sm='post_sm04/'
;   fitsext='_flc.fits'
   fin='_2009'
   prend='_post'
   ztime=2012
   xmin=2009.25
   xmax=2015.3
;   print,sm,fitsext,fin
endif else begin 
   sm='pre_sm04/'
;   fitsext='_flt.fits'
   fin='_2007'
   prend='_pre'
   ztime=2004.5
   xmin=2001.5
   xmax=2007.0
;   print,sm,fitsext,fin
endelse    

dir=dir+sm
locs=[dir+'f435w/nomean/'+prefix+'_*idc.txt',$
      dir+'f606w/nomean/'+prefix+'_*idc.txt',$
      dir+'f814w/nomean/'+prefix+'_*idc.txt']

;idir='/grp/hst/acs/verap/DISTORION_new/';F814W_2007/flt/'
;prefix='040214'+prend ;check a few lines down

;should add more logic here to make it look at different prefixes
;remove f606w to look at all filters
;idcfiles=file_search(dir+'*/nomean/'+prefix+'_*idc.txt',count=numidc)
idcfiles=file_search(locs,count=numidc)
;idcfiles=file_search(dir+'f606w/nomean/0204*idc.txt',count=numidc)
files=strmid(idcfiles,16,9,/reverse_offset)
goodfiles=strmid(idcfiles,16,9,/reverse_offset)
;help,idcfiles

;prefix=prefix+'606'

;print,fitsext,finyr
;print,files

;the bad files should not have made it to this point, this should be unnecessary
bad=file_search(dir+'*/badresid.txt',count=nbad)
if nbad gt 0 then begin
   for i=0,nbad-1 do begin
      if verbose then print,'Looking at badfile: '+bad[i]
      readcol,bad[i],bfiles,format='a',/silent
      if verbose then begin
          print,'Excluding files:'
          forprint,bfiles
      endif

      match,bfiles,files,ind1,ind2,count=nmatches

      if nmatches gt 0 then begin
          print,ind2
          files[ind2]=-9
      endif
   endfor
endif

match,goodfiles,files,ind1,ind2,count=numidc
idcfiles=idcfiles[ind2]
files=files[ind2]

xscale=dblarr(numidc,2)
yrot=dblarr(numidc,2)
yscale=dblarr(numidc,2)
exptime=fltarr(numidc)
roll=fltarr(numidc)
ddate=dblarr(numidc)
filter=strarr(numidc)
vafactor=dblarr(numidc)

for i=0,numidc-1 do begin
   readcol,idcfiles[i],c10,c11,c20,c21,c22,c30,c31,c32,c33,c40,c41,c42,c43,$
      c44,c50,c51,c52,c53,c54,c55,/silent,$
      format='d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d',count=count

   filter[i]=strmid(idcfiles[i],strpos(idcfiles[i],'/f')+1,5)
   if (filter[i] eq 'f606w') and (post eq 1) then finyr='' else finyr=fin 
   ;ifile=idir+strupcase(filter[i])+finyr+'/flt/'+files[i]+fitsext
   ifile=idir+'*/'+files[i]+fitsext
   if verbose then print,'Looking at image: '+ifile
   hdr=headfits(ifile,exten=0)
   hdr1=headfits(ifile,exten=1)
   
   ddate[i]=datesconv(sxpar(hdr,'DATE-OBS'))
   exptime[i]=sxpar(hdr,'EXPTIME')
   roll[i]=sxpar(hdr,'PA_V3')
   vafactor[i]=sxpar(hdr1,'VAFACTOR')

   xscale[i,0]=c11[0] ;xscale chip1
   xscale[i,1]=c11[2] ;xscale chip2
   yrot[i,0]=c11[1] ;yrot chip1
   yrot[i,1]=c11[3] ;yrot chip2
   yscale[i,0]=c10[1] ;yscale chip1
   yscale[i,1]=c10[3] ;yscale chip2
endfor   


;get the filter index
z435=where(filter eq 'f435w',c435)
z606=where(filter eq 'f606w',c606)
z814=where(filter eq 'f814w',c814)

if jay_date then begin
    if verbose then print,'Overriding ddate with Jays date solutions'
    imgdir='/grp/hst/acs2/astrometric_ref/47tuc/wfc/'
    filts=uniq(filter)
    for i=0,n_elements(filts)-1 do begin
        readcol,imgdir+filter[filts[i]]+'/readheader.out',rootname,pid,date_obs,$
            time_obs,ra,dec,pav3,fil,expt,rdate,d,dra,ddec,d,d,d,$
            format='a,l,a,a,a,a,f,a,i,d,d,f,f,a,a,a',/silent

        rdate=rdate+2000
        match,files,rootname,ind1,ind2
        ddate[ind1]=rdate[ind2]
    endfor
endif

if do_va then begin
    yrot[*,0]=yrot[*,0]/vafactor
    yrot[*,1]=yrot[*,1]/vafactor
    xscale[*,0]=xscale[*,0]/vafactor
    xscale[*,1]=xscale[*,1]/vafactor
    yscale[*,0]=yscale[*,0]/vafactor
    yscale[*,1]=yscale[*,1]/vafactor
endif

sigma=99
;fit the data
if fit_606 then begin
   newyear=ddate[z606]-ztime
   coeff1=goodpoly(newyear,yrot[z606,0],1,sigma,cyfit1,newx1,newy1) ;for chip1
   coeff1=poly_fit(newyear,yrot[z606,0],1,/double)
   yrot_a1=coeff1[0]
   yrot_b1=coeff1[1]
   coeff2=goodpoly(newyear,yrot[z606,1],1,sigma,cyfit2,newx2,newy2) ;for chip2
   coeff2=poly_fit(newyear,yrot[z606,1],1,/double)
   yrot_a2=coeff2[0]
   yrot_b2=coeff2[1]
   

   xscl_fit1=goodpoly(newyear,xscale[z606,0],1,sigma,cxfit1,xnewx1,xnewy1) ;for chip1
   xscl_fit1=poly_fit(newyear,xscale[z606,0],1,/double)
   xscl_a1=xscl_fit1[0]
   xscl_b1=xscl_fit1[1]
   xscl_fit2=goodpoly(newyear,xscale[z606,1],1,sigma,cxfit2,xnewx2,xnewy2) ;for chip2
   xscl_fit2=poly_fit(newyear,xscale[z606,1],1,/double)
   xscl_a2=xscl_fit2[0]
   xscl_b2=xscl_fit2[1]


   ;yscale
   yscl_fit1=goodpoly(newyear,yscale[z606,0],1,sigma,cysfit1,ysnewx1,ysnewy1) ;for chip1
   yscl_fit1=poly_fit(newyear,yscale[z606,0],1,/double)
   yscl_a1=yscl_fit1[0]
   yscl_b1=yscl_fit1[1]
   yscl_fit2=goodpoly(newyear,yscale[z606,1],1,sigma,cysfit2,ysnewx2,ysnewy2) ;for chip2
   yscl_fit2=poly_fit(newyear,yscale[z606,1],1,/double)
   yscl_a2=yscl_fit2[0]
   yscl_b2=yscl_fit2[1]

   if n_elements(newx1) ne n_elements(yrot[z606,0]) then begin
      print,'** Things clipped **'
      print,'  # elements before: '+strn(n_elements(yrot[z606,0]))
      print,'  # elements after: '+strn(n_elements(newx1))
      print,'  sigma: '+strn(sigma)
   endif
endif else begin
   newyear=ddate-ztime
   coeff1=goodpoly(newyear,yrot[*,0],1,sigma,cyfit1,newx1,newy1) ;for chip1
   yrot_a1=coeff1[0]
   yrot_b1=coeff1[1]
   coeff2=goodpoly(newyear,yrot[*,1],1,sigma,cyfit2,newx2,newy2) ;for chip2
   yrot_a2=coeff2[0]
   yrot_b2=coeff2[1]
   
   xscl_fit1=goodpoly(newyear,xscale[*,0],1,sigma,cxfit1,xnewx1,xnewy1) ;for chip1
   xscl_a1=xscl_fit1[0]
   xscl_b1=xscl_fit1[1]
   xscl_fit2=goodpoly(newyear,xscale[*,1],1,sigma,cxfit2,xnewx2,xnewy2) ;for chip2
   xscl_a2=xscl_fit2[0]
   xscl_b2=xscl_fit2[1]
   

   ;yscale
   yscl_fit1=goodpoly(newyear,yscale[*,0],1,sigma,cysfit1,ysnewx1,ysnewy1) ;for chip1
   yscl_a1=yscl_fit1[0]
   yscl_b1=yscl_fit1[1]
   yscl_fit2=goodpoly(newyear,yscale[*,1],1,sigma,cysfit2,ysnewx2,ysnewy2) ;for chip2
   yscl_a2=yscl_fit2[0]
   yscl_b2=yscl_fit2[1]

   if n_elements(newx1) ne n_elements(yrot[*,0]) then begin
      print,'** Things clipped **'
      print,'  # elements before: '+strn(n_elements(yrot[*,0]))
      print,'  # elements after: '+strn(n_elements(newx1))
      print,'  sigma: '+strn(sigma)
   endif
endelse

setusym,1
if show_plot then begin
    win=0
    window,win,xsize=1300,ysize=700
    
    !P.Multi = [0,2,2,0,0]
    ;chip2
    plot,ddate,xscale[*,0],xr=[xmin,xmax],xmargin=[15,2],/nodata,ymargin=[2,8],$
       ytitle='arc-sec/pix',title='Chip 1',yr=[minmax(xscale[*,0])],$
       background='ffffff'xl,color='000000'xl
    if exp_time then begin
        for i=0,c435-1 do oplot,[ddate[z435[i]]],[xscale[z435[i],0]],psym=8,$
                             symsize=exptime[z435[i]]/300+1,color='ff0000'xl
        for i=0,c606-1 do oplot,[ddate[z606[i]]],[xscale[z606[i],0]],psym=8,$
                             symsize=exptime[z606[i]]/300+1,color='00ff00'xl
        for i=0,c814-1 do oplot,[ddate[z814[i]]],[xscale[z814[i],0]],psym=8,$
                             symsize=exptime[z814[i]]/300+1,color='0000ff'xl
    endif else begin
        oplot,ddate[z435],xscale[z435,0],psym=8,color='ff0000'xl
        oplot,ddate[z606],xscale[z606,0],psym=8,color='00ff00'xl
        oplot,ddate[z814],xscale[z814,0],psym=8,color='0000ff'xl
    endelse
    if fit_606 then oplot,ddate[z606],cxfit1,color='000000'xl else oplot,ddate,cxfit1,color='000000'xl
    
    ;chip1
    plot,ddate,xscale[*,1],xr=[xmin,xmax],xmargin=[11,3],/nodata,ymargin=[2,8],$
       color='000000'xl,title='Chip 2',yr=[minmax(xscale[*,1])]
    if exp_time then begin
        for i=0,c435-1 do oplot,[ddate[z435[i]]],[xscale[z435[i],1]],psym=8,$
                             symsize=exptime[z435[i]]/300+1,color='ff0000'xl
        for i=0,c606-1 do oplot,[ddate[z606[i]]],[xscale[z606[i],1]],psym=8,$
                             symsize=exptime[z606[i]]/300+1,color='00ff00'xl
        for i=0,c814-1 do oplot,[ddate[z814[i]]],[xscale[z814[i],1]],psym=8,$
                             symsize=exptime[z814[i]]/300+1,color='0000ff'xl
    endif else begin
        oplot,ddate[z435],xscale[z435,1],psym=8,color='ff0000'xl
        oplot,ddate[z606],xscale[z606,1],psym=8,color='00ff00'xl
        oplot,ddate[z814],xscale[z814,1],psym=8,color='0000ff'xl
    endelse

    if fit_606 then oplot,ddate[z606],cxfit2,color='000000'xl else oplot,ddate,cxfit2,color='000000'xl
    
    
    ;chip2
    plot,ddate,yrot[*,0],xr=[xmin,xmax],xmargin=[15,2],/nodata,ymargin=[4,2],$
       ytitle='arc-sec/pix',xtitle='Date (decimil years)',$
       title='Chip 1',color='000000'xl,yr=[minmax(yrot[*,0])]
    if exp_time then begin
        for i=0,c435-1 do oplot,[ddate[z435[i]]],[yrot[z435[i],0]],psym=8,$
                             symsize=exptime[z435[i]]/300+1,color='ff0000'xl
        for i=0,c606-1 do oplot,[ddate[z606[i]]],[yrot[z606[i],0]],psym=8,$
                             symsize=exptime[z606[i]]/300+1,color='00ff00'xl
        for i=0,c814-1 do oplot,[ddate[z814[i]]],[yrot[z814[i],0]],psym=8,$
                             symsize=exptime[z814[i]]/300+1,color='0000ff'xl
    endif else begin
        oplot,ddate[z435],yrot[z435,0],psym=8,color='ff0000'xl
        oplot,ddate[z606],yrot[z606,0],psym=8,color='00ff00'xl
        oplot,ddate[z814],yrot[z814,0],psym=8,color='0000ff'xl
    endelse
    
    if fit_606 then oplot,ddate[z606],cyfit1,color='000000'xl else oplot,ddate,cyfit1,color='000000'xl

    ;chip1
    plot,ddate,yrot[*,1],xr=[xmin,xmax],xmargin=[11,3],/nodata,ymargin=[4,2],$
       title='Chip 2',xtitle='Date (decimil years)',$
       color='000000'xl,yr=[minmax(yrot[*,1])]
    if exp_time then begin
        for i=0,c435-1 do oplot,[ddate[z435[i]]],[yrot[z435[i],1]],psym=8,$
                             symsize=exptime[z435[i]]/300+1,color='ff0000'xl
        for i=0,c606-1 do oplot,[ddate[z606[i]]],[yrot[z606[i],1]],psym=8,$
                             symsize=exptime[z606[i]]/300+1,color='00ff00'xl
        for i=0,c814-1 do oplot,[ddate[z814[i]]],[yrot[z814[i],1]],psym=8,$
                             symsize=exptime[z814[i]]/300+1,color='0000ff'xl
    endif else begin
        oplot,ddate[z435],yrot[z435,1],psym=8,color='ff0000'xl
        oplot,ddate[z606],yrot[z606,1],psym=8,color='00ff00'xl
        oplot,ddate[z814],yrot[z814,1],psym=8,color='0000ff'xl
    endelse                         

    if fit_606 then oplot,ddate[z606],cyfit2,color='000000'xl else oplot,ddate,cyfit2,color='000000'xl

    ;annotize the graphs
    xyouts,.09,.42,'alpha: '+strn(yrot_a1),/normal,color=0
    xyouts,.09,.40,'beta: '+strn(yrot_b1),/normal,color=0
    xyouts,.09,.38,'time0: '+strn(ztime),/normal,color=0
    
    xyouts,.6,.42,'alpha: '+strn(yrot_a2),/normal,color=0
    xyouts,.6,.40,'beta: '+strn(yrot_b2),/normal,color=0
    xyouts,.6,.38,'time0: '+strn(ztime),/normal,color=0
    
    xyouts,.38,.93,'F606W ',/normal,color='00ff00'xl,charsize=2,charthick=2
    xyouts,.5,.93,'F435W ',/normal,color='ff0000'xl,charsize=2,charthick=2
    xyouts,.62,.93,'F814W ',/normal,color='0000ff'xl,charsize=2,charthick=2
    xyouts,.425,.93,' -'+strn(c606),/normal,color=0,charsize=1.5;,charthick=2
    xyouts,.545,.93,' -'+strn(c435),/normal,color=0,charsize=1.5;,charthick=2
    xyouts,.665,.93,' -'+strn(c814),/normal,color=0,charsize=1.5;,charthick=2

    xyouts,.09,.58,'alpha: '+strn(xscl_a1),/normal,color=0
    xyouts,.09,.56,'beta: '+strn(xscl_b1),/normal,color=0
    xyouts,.09,.54,'time0: '+strn(ztime),/normal,color=0
    
    xyouts,.6,.58,'alpha: '+strn(xscl_a2),/normal,color=0
    xyouts,.6,.56,'beta: '+strn(xscl_b2),/normal,color=0
    xyouts,.6,.54,'time0: '+strn(ztime),/normal,color=0
    ;add title
    if post then title='Post SM04 Time Dependency for F606W, F435W & F814W' else $
       title='Pre SM04 Time Dependency for F606W, F435W & F814W'
    xyouts,.3,.96,title,/normal,$
       color=0,charsize=2,charthick=2
    !P.Multi = 0
endif

fmt='(a36,E20.10)'

if write then begin
    timefile=dir+'all/'+prefix+'_sm04_alltime_coeffs.txt' 
    openw,tunit,timefile,/get_lun
    print,'writing: '+timefile
    printf,tunit,'Time dependant beta term for F606W, F435W & F814 '+sm+' data.'
    printf,tunit,'Created on: '+systime()
    printf,tunit,'zero time: ',ztime
    printf,tunit,'yrot beta for chip 1 (exten = 4): ',yrot_b1,format=fmt
    printf,tunit,'yrot beta for chip 2 (exten = 1): ',yrot_b2,format=fmt
    printf,tunit,'yrot alpha for chip 1 (exten = 4): ',yrot_a1,format=fmt
    printf,tunit,'yrot alpha for chip 2 (exten = 1): ',yrot_a2,format=fmt
    printf,tunit,'xscale beta for chip 1 (exten = 4): ',xscl_b1,format=fmt
    printf,tunit,'xscale beta for chip 2 (exten = 1): ',xscl_b2,format=fmt
    printf,tunit,'xscale alpha for chip 1 (exten = 4): ',xscl_a1,format=fmt
    printf,tunit,'xscale alpha for chip 2 (exten = 1): ',xscl_a2,format=fmt
    printf,tunit,'yscale beta for chip 1 (exten = 4): ',yscl_b1,format=fmt
    printf,tunit,'yscale beta for chip 2 (exten = 1): ',yscl_b2,format=fmt
    printf,tunit,'yscale alpha for chip 1 (exten = 4): ',yscl_a1,format=fmt
    printf,tunit,'yscale alpha for chip 2 (exten = 1): ',yscl_a2,format=fmt

    free_lun,tunit
endif


if verbose then begin
    print,'zero time: ',ztime
    print,'yrot beta for chip 1 (exten = 4): ',yrot_b1,format=fmt
    print,'yrot beta for chip 2 (exten = 1): ',yrot_b2,format=fmt
    print,'yrot alpha for chip 1 (exten = 4): ',yrot_a1,format=fmt
    print,'yrot alpha for chip 2 (exten = 1): ',yrot_a2,format=fmt
    print,'xscale beta for chip 1 (exten = 4): ',xscl_b1,format=fmt
    print,'xscale beta for chip 2 (exten = 1): ',xscl_b2,format=fmt
    print,'xscale alpha for chip 1 (exten = 4): ',xscl_a1,format=fmt
    print,'xscale alpha for chip 2 (exten = 1): ',xscl_a2,format=fmt
    print,'yscale beta for chip 1 (exten = 4): ',yscl_b1,format=fmt
    print,'yscale beta for chip 2 (exten = 1): ',yscl_b2,format=fmt
    print,'yscale alpha for chip 1 (exten = 4): ',yscl_a1,format=fmt
    print,'yscale alpha for chip 2 (exten = 1): ',yscl_a2,format=fmt
endif


end
