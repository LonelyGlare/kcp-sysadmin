# 


## 
### 


Se ha de lanzar el comando vagrant up
Acceder a las pagina localhost:8081 en un navegador web y seguir el asistente de configuracion de WordPress


- Wordpress:

    1. Abrir la url <code>http://localhost:8081</code> en el navegador.
    2. Seguir el asistente de configuración que se muestra.
    ![snapshots/wordpress-1.png](./snapshots/wordpress-1.png)
    3. Tras hacer login se mostrará el Dashboard.
    ![snapshots/wordpress-3.png](./snapshots/wordpress-3.png)


- Monitorización con Kibana:

    1. Abrir la url <code>http://localhost:8080</code> en el navegador.
    2. Identificarse con el usuario <code>kibanaadmin</code> y la contraseña indicada previamente en el fichero *.kibana*.
    ![snapshots/kibana-2.png](./snapshots/kibana-2.png)
    3. Desde <code>Management-Stack Management-Index Patterns</code>, crear un <code>index-pattern</code> de nombre <code>filebeat-*</code> y seleccionar <code>timestamp</code> como campo de referencia de tiempo.
    ![snapshots/kibana-3.png](./snapshots/kibana-3.png)
    ![snapshots/kibana-5.png](./snapshots/kibana-5.png)
    4. Desde la opción de menú <code>Discover</code> se pueden consultar los logs una vez realizado el paso previo.
    ![snapshots/kibana-6.png](./snapshots/kibana-6.png)
    ![snapshots/kibana-7.png](./snapshots/kibana-7.png)
    ![snapshots/kibana-8.png](./snapshots/kibana-8.png)
    