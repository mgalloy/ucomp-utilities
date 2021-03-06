; docformat = 'rst'

pro ucomp_spectral_profile, filename, pol_state, beam, x, y, error=error
  compile_opt strictarr

  error = 0L

  ucomp_query_file, filename, wavelength=wavelengths

  all_wavelengths = wavelengths[indices]
  nx = 3
  ny = 3
  all_spectrum = fltarr(nx, ny, n_wavelengths)
  fits_open, filename, fcb
  for w = 0L, n_wavelengths - 1L do begin
    fits_read, fcb, data, exten_no=indices[w] + 1
    all_spectrum[*, *, w] = data[x - nx / 2:x + nx / 2, y - nx / 2: y + nx / 2]
  endfor
  fits_close, fcb

  ; sort arrays to average duplicates in wavelengths
  sort_ind = sort(all_wavelengths)
  all_wavelengths = all_wavelengths[sort_ind]
  all_spectrum    = all_spectrum[*, *, sort_ind]

  uniq_ind = uniq(all_wavelengths)
  wavelengths = all_wavelengths[uniq_ind]
  spectrum = fltarr(nx, ny, n_elements(uniq_ind))
  last_ind = 0L
  for i = 0L, n_elements(uniq_ind) - 1L do begin
    w = reform(all_spectrum[*, *, last_ind:uniq_ind[i]], nx, ny, uniq_ind[i] - last_ind + 1L)
    spectrum[*, *, i] = mean(w, dimension=3)
    last_ind = uniq_ind[i] + 1
  endfor

  window, /free, xsize=700, ysize=275, retain=2, $
          title=string(file_basename(filename), format='(%"Spectral plot for %s")')

  device, get_decomposed=original_decomposed
  device, decomposed=1

  plot, wavelengths, spectrum[nx / 2, ny / 2, *], xstyle=9, ystyle=8, /nodata, $
        yrange=[min(spectrum, max=max_spectrum), max_spectrum], $
        xtitle='Wavelength (nm)', ytitle='Value', $
        title=string(file_basename(filename), pol_state, beam, x, y, $
                     format='(%"Spectrum for %s @ %s, beam %d, x:%d, y:%d")')

  radius = sqrt((nx / 2)^2 + (ny / 2)^2)
  for i = 0L, nx - 1L do begin
    for j = 0L, ny - 1L do begin
      if ((i ne nx / 2) || (j ne ny / 2)) then begin
        r = 128L * sqrt((nx / 2 - i)^2 + (ny / 2 - j)^2) / radius
        color = long(r) * (1 + 2L^8 + 2L^16)
        oplot, wavelengths, spectrum[i, j, *], color=color
      endif
    endfor
  endfor

  oplot, wavelengths, spectrum[nx / 2, ny / 2, *], thick=2, psym=-6

  if (n_elements(wavelengths) eq 17) then begin
    original_ind = [0, 4, 8, 12, 16]
  endif else begin
    original_ind = lindgen(n_elements(wavelengths))
  endelse

  usersym, [-1, 1, 1, -1, -1], [1, 1, -1, -1, 1], /fill
  oplot, wavelengths[original_ind], (spectrum[nx / 2, ny / 2, *])[original_ind], $
         psym=8, color='0000ff'x

  device, decomposed=original_decomposed
end


; main-level example program

filename = '20160605.184110.comp.1083.iquv.17.fts'
comp_spectral_profile, filename, 'I', 0, 154, 525

end
