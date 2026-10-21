<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %><c:if test="${not empty sessionScope.idUsuario}"><c:catch var="errorAuditarSalida"><sql:update dataSource="${db}">INSERT INTO parcial_julian.auditoria(usuario_id,entidad,accion,detalle) VALUES(CAST(? AS BIGINT),'sesion','CIERRE_SESION','Salida voluntaria del sistema')<sql:param value="${sessionScope.idUsuario}"/></sql:update></c:catch></c:if><c:remove var="idUsuario" scope="session"/><c:remove var="rol" scope="session"/><c:remove var="nombre" scope="session"/><c:remove var="csrf" scope="session"/><c:redirect url="/login.jsp"/>
