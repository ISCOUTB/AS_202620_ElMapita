## `.gitignore`

Se agregó la siguiente línea para evitar que el archivo de entorno local con valores reales se suba al repositorio:

```
deploy/.env
```

Esto garantiza que los secretos nunca queden versionados en Git.
