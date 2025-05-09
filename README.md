# k8s_forensics

Super lightweight bash script to gather forensic triage data about k8s resources of a k8s cluster.

It's a contribution to the **DFIR** community to further enhance the field of container forensics.

---

## 🚀 Features

- Gather information about the following k8s objects from a cluster:
  - **cluster info**
  - **namespaces**
  - **pod, containers and services of a namespace**
  - **pod and container logs**
  - **environment variables of a container**
  - **metrics of a pod**
- Creates archive file of the results
- Creates a log file of each execution incl. the hash of the archive (chain of custody)

## 🧱 Prerequisites

- kubectl
- tar
- k8s permissions to read cluster information

---

## 🧪 Usage

Execute script:

```bash
./k8s-ContainerTriageCollection
```

📁 You'll find all findings:

- Archive: `<script_dir>/Collection/<timestamp>_kubernetes_collections.tar`
- Log File: `<script_dir>/Collection/collection-log-<timestamp>.txt`

---

## 📄 License

MIT License — Free to use, improve, and share.
