------------------------------------ SCHEMA CREATION ------------------------------------

CREATE TABLE pais(
  	id_pais SERIAL NOT NULL PRIMARY KEY,
  	pais TEXT NOT NULL,
  	UNIQUE (pais)
);

CREATE TABLE provincia(
  	provincia INT NOT NULL PRIMARY KEY ,
  	id_pais INT NOT NULL,
  	FOREIGN KEY (id_pais) REFERENCES pais ON DELETE RESTRICT
);

CREATE TABLE departamento(
  	id_departamento SERIAL NOT NULL PRIMARY KEY,
  	departamento TEXT NOT NULL,
  	provincia INT NOT NULL,
  	FOREIGN KEY (provincia) REFERENCES provincia ON DELETE RESTRICT,
  	UNIQUE (departamento, provincia)
);

CREATE TABLE localidad (
  	id_localidad SERIAL NOT NULL PRIMARY KEY,
  	nombre TEXT NOT NULL,
  	canthab INT,
  	id_departamento INT NOT NULL,
  	FOREIGN KEY (id_departamento) REFERENCES departamento ON DELETE RESTRICT,
  	UNIQUE (nombre, id_departamento)
 );

------------------------------------------- DATA IMPORT -------------------------------------------

CREATE OR REPLACE FUNCTION insert_csv_row() RETURNS trigger AS $$
DECLARE
	pais_id int;
  departamento_id int;
  localidad_nombre_upper text;
  departamento_upper text;
  pais_upper text;
BEGIN
  localidad_nombre_upper := upper(NEW.nombre);
  departamento_upper := upper(New.departamento);
  pais_upper := upper(NEW.pais);
	IF NOT EXISTS(SELECT * FROM pais WHERE pais.pais=pais_upper) THEN
		INSERT into pais (pais) VALUES (pais_upper);
    END IF;

    IF NOT EXISTS(SELECT * FROM provincia WHERE provincia.provincia=NEW.provincia) THEN
        SELECT id_pais FROM pais WHERE pais.pais=pais_upper INTO pais_id;
        INSERT into provincia(provincia,id_pais) VALUES(NEW.provincia,pais_id);
    END IF;

    IF NOT EXISTS(SELECT * FROM departamento WHERE departamento.departamento=departamento_upper and departamento.provincia=New.provincia) THEN
        INSERT into departamento(departamento,provincia) VALUES(departamento_upper,NEW.provincia);
    End IF;

    SELECT id_departamento FROM departamento WHERE (departamento.departamento=departamento_upper AND departamento.provincia=New.provincia)INTO departamento_id;
    IF NOT EXISTS(SELECT * FROM localidad WHERE localidad.nombre=localidad_nombre_upper and localidad.id_departamento=departamento_id) THEN
    	 INSERT INTO localidad (nombre,canthab,id_departamento) VALUES(localidad_nombre_upper,new.canthab,departamento_id);
    ELSE
      update localidad
      set canthab = new.canthab
      where id_departamento = departamento_id and nombre = localidad_nombre_upper;
    	RAISE notice 'Se actualizó una localidad';
    End IF;


    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE VIEW csv_view AS(
    SELECT localidad.nombre,
           pais.pais,
           provincia.provincia,
           departamento.departamento,
           localidad.canthab
    FROM pais
             NATURAL JOIN provincia
             NATURAL JOIN departamento
             NATURAL JOIN localidad
);

CREATE TRIGGER insert_csv_row INSTEAD OF INSERT ON csv_view
FOR EACH ROW EXECUTE PROCEDURE insert_csv_row();

COPY csv_view FROM 'INGRESE_DIRECCION_CSV' (FORMAT CSV, HEADER, ENCODING 'UTF8');

------------------------------------------- DATA DELETE -------------------------------------------

CREATE OR REPLACE FUNCTION delete_csv_row() RETURNS trigger AS $$
DECLARE
    locId int; depId int; paisId int;
BEGIN

    SELECT id_pais FROM pais WHERE pais.pais=old.pais INTO paisId;
    SELECT id_departamento FROM departamento WHERE departamento.departamento=old.departamento AND provincia=old.provincia INTO depId;
    SELECT id_localidad FROM localidad WHERE localidad.nombre=old.nombre AND localidad.id_departamento=depId INTO locId;

    DELETE FROM localidad WHERE localidad.id_localidad=locId;

    IF NOT EXISTS(SELECT * FROM localidad WHERE localidad.id_departamento = depId) THEN
        DELETE FROM departamento WHERE departamento.id_departamento = depId;
    END IF;

    IF NOT EXISTS(SELECT * FROM departamento WHERE departamento.provincia = old.provincia) THEN
        DELETE FROM provincia WHERE provincia.provincia = old.provincia;
    END IF;

    IF NOT EXISTS(SELECT * FROM provincia WHERE provincia.id_pais = paisId) THEN
        DELETE FROM pais WHERE pais.id_pais = paisId;
    END IF;

    RETURN NULL;

END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER delete_csv_row INSTEAD OF DELETE ON csv_view
FOR EACH ROW EXECUTE PROCEDURE delete_csv_row();