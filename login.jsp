<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<c:catch var="errorInicializacion"><%@ include file="/WEB-INF/jspf/bootstrap.jspf" %></c:catch>
<c:if test="${not empty sessionScope.idUsuario}"><c:redirect url="/panel.jsp"/></c:if>
<c:if test="${pageContext.request.method eq 'POST' and empty errorInicializacion and empty inicializacionError}">
<c:choose><c:when test="${empty param.correo or empty param.clave}"><c:set var="errorLogin" value="Escribe el correo y la contraseña."/></c:when>
<c:otherwise>
<c:catch var="errorConsulta"><sql:query var="ingreso" dataSource="${db}">SELECT id,nombre,rol FROM parcial_julian.usuarios WHERE lower(correo)=lower(btrim(CAST(? AS TEXT))) AND clave_hash=encode(sha256(convert_to(sal||CAST(? AS TEXT),'UTF8')),'hex') AND activo=TRUE LIMIT 1
<sql:param value="${param.correo}"/><sql:param value="${param.clave}"/></sql:query></c:catch>
<c:choose><c:when test="${not empty errorConsulta}"><c:set var="errorLogin" value="No se pudo completar la consulta a la base de datos."/></c:when><c:when test="${ingreso.rowCount eq 1}">
<c:set var="idUsuario" value="${ingreso.rows[0].id}" scope="session"/><c:set var="rol" value="${ingreso.rows[0].rol}" scope="session"/><c:set var="nombre" value="${ingreso.rows[0].nombre}" scope="session"/>
<c:catch><sql:query var="tokenNuevo" dataSource="${db}">SELECT gen_random_uuid()::text AS valor</sql:query></c:catch>
<c:set var="csrf" value="${tokenNuevo.rows[0].valor}" scope="session"/>
<c:catch var="errorAuditarIngreso"><sql:update dataSource="${db}">INSERT INTO parcial_julian.auditoria(usuario_id,entidad,accion,detalle) VALUES(CAST(? AS BIGINT),'sesion','INICIO_SESION','Acceso al panel de NEXO Académico')
<sql:param value="${ingreso.rows[0].id}"/></sql:update></c:catch><c:redirect url="/panel.jsp"/>
</c:when><c:otherwise><c:set var="errorLogin" value="Credenciales incorrectas o cuenta inactiva."/></c:otherwise></c:choose>
</c:otherwise></c:choose></c:if>
<!doctype html><html lang="es"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Acceso · NEXO UTS</title><link rel="stylesheet" href="<c:url value='/assets/estilos.css'/>?v=3"></head>
<body class="login-bg"><div class="login-wrap"><section class="login-intro"><div class="login-campus"><img src="<c:url value='/assets/logo-uts.png'/>" alt="Logo de Ingeniería de Sistemas UTS"></div><span class="eyebrow">UNIDADES TECNOLÓGICAS DE SANTANDER</span><h1>Tu avance académico,<br><em>en un solo lugar.</em></h1><p>Una plataforma para conectar estudiantes, docentes y coordinación durante el desarrollo de anteproyectos de grado.</p><div class="login-steps"><span>01 · Presenta tu idea</span><span>02 · Recibe retroalimentación</span><span>03 · Avanza con claridad</span></div><div class="intro-foot">Proyecto académico desarrollado por <strong>Julián Santiago Lache Leguízamo</strong></div></section>
<section class="login-card"><div class="login-card-top"><div class="minilogo">N</div><span class="pill">PORTAL ACADÉMICO</span></div><h2>¡Qué gusto verte!</h2><p>Inicia sesión con la cuenta asignada por el Administrador.</p>
<c:if test="${not empty errorInicializacion or not empty inicializacionError}"><div class="alert bad">No se pudo inicializar la base de datos. Revisa la conexión de Supabase y los registros de Tomcat.</div></c:if>
<c:if test="${not empty errorLogin}"><div class="alert bad"><c:out value="${errorLogin}"/></div></c:if>
<form method="post" action="<c:url value='/login.jsp'/>"><label>Correo electrónico<input name="correo" type="email" maxlength="180" required placeholder="correo@institucion.edu.co" autocomplete="username"></label><label>Contraseña<input name="clave" type="password" required autocomplete="current-password" placeholder="Introduce tu contraseña"></label><button class="primary wide" type="submit">Ingresar al sistema <span>→</span></button></form>
</section></div></body></html>
