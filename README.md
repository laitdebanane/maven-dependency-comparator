# Maven Dependency Comparator

A bash script that compares dependencies of different effective pom.xml files.

## Usage

Example usage:

```bash
bin/script.sh ~/projects/project_A/pom.xml ~/projects/project_B/pom.xml
```

For more options:

```bash
bin/script.sh --help
```

## Formats

Three output formats are available: **simple** (default), **inline**, and **markdown**.

### Simple

The **simple** format is ideal for quick reading and checking of dependencies.

This command...

```bash
bin/script.sh ~/projects/project_A/pom.xml ~/projects/project_B/pom.xml --format simple
```

... will yield this output:

```
<<< First pom.xml's dependencies >>>
com.mycompany.project datamodel 0.5.0
com.h2database h2 1.4.191
log4j apache-log4j-extras 1.2.17
mysql mysql-connector-java 5.1.39
org.apache.hadoop hadoop-common 2.6.0
org.springframework.boot spring-boot-starter 1.3.5.RELEASE

<<< Second pom.xml's dependencies >>>
com.mycompany.project.commons datamodel 0.5.7
com.h2database h2 1.4.196
log4j apache-log4j-extras 1.2.17
mysql mysql-connector-java 5.1.39
org.apache.hadoop hadoop-common 2.6.0
org.springframework.boot spring-boot-starter 1.3.5.RELEASE
```

### Inline

The **inline** format is ideal for subsequent analysis by another script.

This command...

```bash
bin/script.sh ~/projects/project_A/pom.xml ~/projects/project_B/pom.xml --format inline
```

... will yield this output:

```
com.mycompany.project.commons datamodel <none> 0.5.7
com.mycompany.project datamodel 0.5.0 <none>
com.h2database h2 1.4.191 1.4.196
log4j apache-log4j-extras 1.2.17 1.2.17
mysql mysql-connector-java 5.1.39 5.1.39
org.apache.hadoop hadoop-common 2.6.0 2.6.0
org.springframework.boot spring-boot-starter 1.3.5.RELEASE 1.3.5.RELEASE
```

### Markdown

The **markdown** format is ideal for inclusion in reports and other documents.

This command...

```bash
bin/script.sh ~/projects/project_A/pom.xml ~/projects/project_B/pom.xml --format markdown
```

... will yield this output:

```markdown
| groupId | artifactId | first version | second version |
|:---:|:---:|:---:|:---:|
| com.mycompany.project.commons | datamodel | <none> | 0.5.7 |
| com.mycompany.project | datamodel | 0.5.0 | <none> |
| **com.h2database** | **h2** | **1.4.191** | **1.4.196** |
| log4j | apache-log4j-extras | 1.2.17 | 1.2.17 |
| mysql | mysql-connector-java | 5.1.39 | 5.1.39 |
| org.apache.hadoop | hadoop-common | 2.6.0 | 2.6.0 |
| org.springframework.boot | spring-boot-starter | 1.3.5.RELEASE | 1.3.5.RELEASE |
```

... which, when rendered, yields this:

| groupId | artifactId | first version | second version |
|:---:|:---:|:---:|:---:|
| com.mycompany.project.commons | datamodel | <none> | 0.5.7 |
| com.mycompany.project | datamodel | 0.5.0 | <none> |
| **com.h2database** | **h2** | **1.4.191** | **1.4.196** |
| log4j | apache-log4j-extras | 1.2.17 | 1.2.17 |
| mysql | mysql-connector-java | 5.1.39 | 5.1.39 |
| org.apache.hadoop | hadoop-common | 2.6.0 | 2.6.0 |
| org.springframework.boot | spring-boot-starter | 1.3.5.RELEASE | 1.3.5.RELEASE |
