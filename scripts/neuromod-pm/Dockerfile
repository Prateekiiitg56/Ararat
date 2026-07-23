FROM ubuntu:24.04
RUN useradd -m -u 1000 appuser
WORKDIR /home/appuser
COPY plant_model.sh .
RUN chmod +x plant_model.sh && chown -R appuser:appuser /home/appuser
USER appuser
CMD ["/bin/bash", "plant_model.sh"]


