FROM tomcat:9.0-jdk17-temurin-jammy

# Dejar tu proyecto como la aplicación principal del servidor
RUN rm -rf /usr/local/tomcat/webapps/*
COPY . /usr/local/tomcat/webapps/ROOT/

# Que Tomcat escuche en el puerto que indique Render (variable PORT)
RUN sed -i 's/port="8080"/port="${port.http}"/' /usr/local/tomcat/conf/server.xml

# Limitar la memoria: el plan gratis de Render tiene 512 MB
ENV JAVA_OPTS="-Xms64m -Xmx256m"

EXPOSE 8080

CMD ["sh", "-c", "export JAVA_OPTS=\"$JAVA_OPTS -Dport.http=${PORT:-8080}\" && exec catalina.sh run"]